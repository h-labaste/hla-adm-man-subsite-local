using GestionSousSite.Data.Models;
using GestionSousSite.Features.Sites.Models;
using GestionSousSite.Services;

namespace GestionSousSite.Features.Sites.Services
{
  public class SitesService
  {

    private readonly IWebHostEnvironment _env;
    private readonly AzureDevOpsService _devOpsService;
    private string _scriptFolderName = "Scripts";
    private string _scriptFolder { get { return Path.Combine(_env.ContentRootPath, _scriptFolderName); } }
    private IPowerShellAdapter _adapter;
    private string _scriptPath(string scriptFileName)
    {
      return Path.Combine(_scriptFolder, scriptFileName);
    }

    public SitesService(IWebHostEnvironment env, AzureDevOpsService devOpsService)
    {
      _env = env;
      _devOpsService = devOpsService;
      _adapter = PowerShellAdapterFactory.Create();
    }

    public string GetRootPath()
    {
      return _env.ContentRootPath; // Racine de l'application
    }

    public string GetWebRootPath()
    {
      return _env.WebRootPath; // Chemin vers wwwroot
    }

    public List<SousSite> GetSousSites(DrivePathInfo drive)
    {
      var sousSites = new List<SousSite>();

      if (!string.IsNullOrEmpty(drive.Path) && !string.IsNullOrEmpty(drive.SubDirFormat) && Directory.Exists(drive.Path))
      {
        var directories = Directory.GetDirectories(drive.Path, drive.SubDirFormat);

        foreach (var dir in directories)
        {
          var directoryName = Path.GetFileName(dir);
          var subdomainName = directoryName.Substring(2); // Supprime "f-" du nom
          sousSites.Add(new SousSite
          {
            // Main
            Drive = drive,
            // Current SubDomain
            Name = subdomainName,
            SubDnsName = $"{subdomainName}.{drive.DnsName}",
            SubDirName = directoryName,
            SubPath = dir,
            // Test de Configuration
            SubIsConfigured = drive.IsSiteConfigured(dir)
          });
        }
      }

      return sousSites;
    }

    public async Task<(bool Succeeded, string StatusMessage)> DeleteSubsite(string subdomainName, string path)
    {
      return await Task.Run(() =>
      {
        try
        {
          var parameters = new Dictionary<string, string>
          {
            { "SubdomainName", subdomainName },
            { "SubdomainPath", Path.Combine(subdomainName, $"f-{subdomainName}") },
            { "WebConfigPath", Path.Combine(path, "web.config") }
          };

          // Exécute le script via l'adapter
          string result = _adapter.ExecuteScript(_scriptPath("0002--delete-subsite.ps1"), parameters);

          return (true, $"Sous-site '{subdomainName}' supprimé avec succès : {result}");
        }
        catch (Exception ex)
        {
          return (false, $"Erreur : {ex.Message}");
        }
      });
    }

    public async Task<(bool Succeeded, string StatusMessage)> CreateSubsite(string subdomainName, string path)
    {
      return await Task.Run(() =>
      {
        try
        {
          var parameters = new Dictionary<string, string>
          {
            { "SubdomainName", subdomainName },
            { "DomainUrl", $"{subdomainName}.dev.mon-domain.com" },
            { "SubdomainPath", Path.Combine(path, $"f-{subdomainName}") },
            { "WebConfigPath", Path.Combine(path, "web.config") }
          };

          // Exécute le script via l'adapter
          string result = _adapter.ExecuteScript(_scriptPath("0001--subsite-deploy.ps1"), parameters);

          return (true, $"Sous-site '{subdomainName}' créé avec succès : {result}");
        }
        catch (Exception ex)
        {
          return (false, $"Erreur : {ex.Message}");
        }
      });
    }


    public async Task<(bool Succeeded, string StatusMessage)> InitializeSite(string siteName)
    {
      try
      {
        string organization = "VotreOrganisation";
        string project = "VotreProjet";
        string repositoryId = "VotreRepositoryId";
        string branchName = $"refs/heads/feature/{siteName}";
        string pipelineName = $"Pipeline Dynamique - {siteName}";
        string azureDevOpsBaseUrl = $"https://dev.azure.com/{organization}/{project}/_apis";
        string token = "VotreTokenAzureDevOps";

        using var client = new HttpClient();
        client.DefaultRequestHeaders.Authorization = new System.Net.Http.Headers.AuthenticationHeaderValue("Bearer", token);

        // Étape 1 : Vérifier si la pipeline existe
        var pipelinesResponse = await client.GetAsync($"{azureDevOpsBaseUrl}/pipelines?api-version=7.1-preview.1");

        if (!pipelinesResponse.IsSuccessStatusCode)
        {
          var error = await pipelinesResponse.Content.ReadAsStringAsync();
          return (false, $"Erreur lors de la récupération des pipelines : {error}");
        }
        // Désérialiser la réponse en PipelineResponse
        var pipelines = await _devOpsService.ListPipelinesAsync(project);

        // Rechercher la pipeline par nom
        var existingPipeline = pipelines.FirstOrDefault(p => p.Name == pipelineName);

        int pipelineId = existingPipeline != null ? existingPipeline.Id : -1;

        // Étape 2 : Créer la pipeline si elle n'existe pas
        if (pipelineId == -1)
        {
          var createPipelinePayload = new
          {
            name = pipelineName,
            folder = "\\Dynamique",
            configuration = new
            {
              type = "yaml",
              path = "/azure-pipelines.yml",
              repository = new
              {
                id = repositoryId,
                type = "azureReposGit"
              },
              branch = branchName
            }
          };

          var createPipelineResponse = await client.PostAsJsonAsync($"{azureDevOpsBaseUrl}/pipelines?api-version=7.1-preview.1", createPipelinePayload);

          if (!createPipelineResponse.IsSuccessStatusCode)
          {
            var error = await createPipelineResponse.Content.ReadAsStringAsync();
            return (false, $"Erreur lors de la création de la pipeline : {error}");
          }

          var pipelineData = await createPipelineResponse.Content.ReadFromJsonAsync<dynamic>();
          pipelineId = pipelineData?.id;
        }

        // Étape 3 : Déclencher la pipeline
        var runPipelinePayload = new
        {
          resources = new
          {
            repositories = new
            {
              self = new
              {
                refName = branchName
              }
            }
          },
          variables = new
          {
            SiteName = new { value = siteName }
          }
        };

        var runPipelineResponse = await client.PostAsJsonAsync($"{azureDevOpsBaseUrl}/pipelines/{pipelineId}/runs?api-version=7.1-preview.1", runPipelinePayload);

        if (runPipelineResponse.IsSuccessStatusCode)
        {
          return (true, $"Pipeline déclenchée avec succès pour le site {siteName}.");
        }
        else
        {
          var error = await runPipelineResponse.Content.ReadAsStringAsync();
          return (false, $"Erreur lors du déclenchement de la pipeline : {error}");
        }
      }
      catch (Exception ex)
      {
        return (false, $"Erreur : {ex.Message}");
      }
    }
  }

}
