namespace GestionSousSite.Services
{
  using GestionSousSite.Features.Pipelines.Models;

  using Microsoft.Azure.Pipelines.WebApi;
  using Microsoft.TeamFoundation.Build.WebApi;
  using Microsoft.TeamFoundation.SourceControl.WebApi;
  using Microsoft.VisualStudio.Services.Common;
  using Microsoft.VisualStudio.Services.WebApi;

  using Newtonsoft.Json;

  using System.IO;

  using YamlDotNet.RepresentationModel;

  public class AzureDevOpsService
  {
    private readonly string _organizationUrl;
    private readonly string _personalAccessToken;

    private List<GitBranchStats> _branches = [];
    private Dictionary<string, List<GitBranchStats>> _branchesCache = [];
    private Dictionary<string, List<string>> _projectRepoCache = [];

    public AzureDevOpsService(string organizationUrl, string personalAccessToken)
    {
      _organizationUrl = organizationUrl;
      _personalAccessToken = personalAccessToken;
    }
    #region BRANCH

    public async Task<List<string>> GetBranchesAsync(string project, string repositoryId, bool reloadCacheBranche = false)
    {

      if (!_projectRepoCache.ContainsKey(project))
      {
        _projectRepoCache.Add(project, []);
      }
      if (!_projectRepoCache[project].Contains(repositoryId))
      {
        _projectRepoCache[project].Add(repositoryId);
      }

      if (!_branchesCache.ContainsKey(repositoryId))
      {
        _branchesCache.Add(repositoryId, []);
      }
      if (reloadCacheBranche)
      {
        _branchesCache[repositoryId] = [];
      }
      if (_branchesCache[repositoryId].Count == 0)
      {
        var credentials = new VssBasicCredential(string.Empty, _personalAccessToken);
        var connection = new VssConnection(new Uri(_organizationUrl), credentials);

        var gitClient = await connection.GetClientAsync<GitHttpClient>();
        _branchesCache[repositoryId] = await gitClient.GetBranchesAsync(project, repositoryId);
      }
      _branches = _branchesCache[repositoryId];
      return _branches.Select(branch => branch.Name).ToList();
    }

    public async Task<IEnumerable<string>> SearchBranchesAsync(string searchText, string project, string repositoryId, bool reloadCacheBranche = false, int limitResultTo = 50)
    {
      await GetBranchesAsync(project, repositoryId, reloadCacheBranche);
      // Filtrer les branches
      return _branches
        .Where(branch => branch.Name.Contains(searchText, StringComparison.OrdinalIgnoreCase))
        .Select(branch => branch.Name)
        .Take(limitResultTo); // Limiter les résultats
    }

    #endregion

    #region PIPELINE
    // Obtenir les détails d'une pipeline
    public async Task<BuildDefinition> GetPipelineDetailsAsync(string project, int pipelineId)
    {
      var connection = new VssConnection(new Uri(_organizationUrl), new VssBasicCredential(string.Empty, _personalAccessToken));
      var buildClient = await connection.GetClientAsync<BuildHttpClient>();

      return await buildClient.GetDefinitionAsync(project, pipelineId);
    }

    // Méthode pour déclencher une pipeline avec des paramètres
    public async Task TriggerPipelineWithParametersAsync(string project, int pipelineId, Dictionary<string, string> parameters)
    {
      var credentials = new VssBasicCredential(string.Empty, _personalAccessToken);
      var connection = new VssConnection(new Uri(_organizationUrl), credentials);

      var pipelineClient = await connection.GetClientAsync<BuildHttpClient>();
      var pipelineParameters = new Dictionary<string, object>();

      foreach (var param in parameters)
      {
        pipelineParameters[param.Key] = param.Value;
      }

      var build = new Build
      {
        Definition = new DefinitionReference { Id = pipelineId },
        Parameters = JsonConvert.SerializeObject(pipelineParameters)
      };

      await pipelineClient.QueueBuildAsync(build, project);
      connection.Disconnect();
    }

    public async Task<List<Pipeline>> ListPipelinesAsync(string project)
    {
      var connection = new VssConnection(new Uri(_organizationUrl), new VssBasicCredential(string.Empty, _personalAccessToken));
      var pipelinesClient = await connection.GetClientAsync<PipelinesHttpClient>();

      var pipelines = await pipelinesClient.ListPipelinesAsync(project) ?? new List<Pipeline>();
      return pipelines.OrderByDescending(x => x.Id).Take(2).ToList();
    }
    // Exemple de méthode pour gérer les pipelines en fonction de leur type de processus
    public async Task<List<PipelineParameter>> GetPipelineParametersAsync(string project, int pipelineId)
    {
      var connection = new VssConnection(new Uri(_organizationUrl), new VssBasicCredential(string.Empty, _personalAccessToken));
      var buildClient = await connection.GetClientAsync<BuildHttpClient>();

      var buildDefinition = await buildClient.GetDefinitionAsync(project, pipelineId);
      var parameters = new List<PipelineParameter>();

      switch (buildDefinition.Process)
      {
        case YamlProcess yamlProcess:
          if (!string.IsNullOrEmpty(yamlProcess.YamlFilename))
          {
            var yaml = await GetYamlFileContentAsync(project, buildDefinition.Repository.Id, buildDefinition.Repository.DefaultBranch.Replace("refs/heads/", ""), yamlProcess.YamlFilename);
            var list = ParseYamlParameters(yaml);
            parameters.AddRange(list);
          }
          break;

        case DesignerProcess designerProcess:
          // Pour DesignerProcess, extraire les paramètres disponibles
          if (designerProcess.Phases != null)
          {
            foreach (var phase in designerProcess.Phases)
            {
              foreach (var step in phase.Steps)
              {
                if (step.Inputs != null)
                {
                  foreach (var input in step.Inputs)
                  {
                    parameters.Add(new PipelineParameter
                    {
                      Name = input.Key,
                      DefaultValue = input.Value,
                      Type = "string" // DesignerProcess ne fournit pas explicitement de type
                    });
                  }
                }
              }
            }
          }
          break;

        default:
          Console.WriteLine($"Process type not supported: {buildDefinition.Process.GetType().Name}");
          break;
      }
      connection.Disconnect();
      return parameters;
    }
    #region YAML
    private async Task<string> GetYamlFileContentAsync(string project, string repositoryId, string branch, string yamlFilename)
    {
      try
      {
        // Créer une connexion avec Azure DevOps
        var connection = new VssConnection(new Uri(_organizationUrl), new VssBasicCredential(string.Empty, _personalAccessToken));
        var gitClient = await connection.GetClientAsync<GitHttpClient>();

        // Télécharger le fichier YAML depuis le référentiel
        var fileContent = await gitClient.GetItemTextAsync(
          project: project,
          repositoryId: repositoryId,
          path: yamlFilename,
          versionDescriptor: new GitVersionDescriptor
          {
            Version = branch,
            VersionType = GitVersionType.Branch
          }
        );
        connection.Disconnect();
        using var reader = new StreamReader(fileContent);
        return await reader.ReadToEndAsync();
      }
      catch (Exception ex)
      {
        Console.WriteLine($"Erreur lors de la récupération du fichier YAML : {ex.Message}");
        throw;
      }
    }

    public List<PipelineParameter> ParseYamlParameters(string yamlContent)
    {
      try
      {
        var parameters = new List<PipelineParameter>();
        var input = new StringReader(yamlContent);

        // Charger le document YAML
        var yaml = new YamlStream();
        yaml.Load(input);

        // Parcourir les nœuds YAML
        var rootNode = (YamlMappingNode)yaml.Documents[0].RootNode;
        if (rootNode.Children.ContainsKey("parameters"))
        {
          var parameterNodes = (YamlSequenceNode)rootNode.Children[new YamlScalarNode("parameters")];
          foreach (YamlMappingNode paramNode in parameterNodes)
          {
            var name = paramNode.Children[new YamlScalarNode("name")].ToString();
            var defaultValue = paramNode.Children.ContainsKey(new YamlScalarNode("default"))
                ? paramNode.Children[new YamlScalarNode("default")].ToString()
                : null;
            var type = paramNode.Children.ContainsKey(new YamlScalarNode("type"))
                ? paramNode.Children[new YamlScalarNode("type")].ToString()
                : "string";

            parameters.Add(new PipelineParameter
            {
              Name = name,
              DefaultValue = defaultValue ?? string.Empty,
              Type = type
            });
          }
        }

        return parameters;
      }
      catch
      {
        return [];
      }
    }
    #endregion YAML
    #endregion PIPELINE

  }
}
