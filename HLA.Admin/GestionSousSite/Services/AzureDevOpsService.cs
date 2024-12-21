namespace GestionSousSite.Services
{
  using Microsoft.TeamFoundation.Build.WebApi;
  using Microsoft.TeamFoundation.SourceControl.WebApi;
  using Microsoft.VisualStudio.Services.Common;
  using Microsoft.VisualStudio.Services.WebApi;
  using Newtonsoft.Json;
  using Microsoft.Azure.Pipelines.WebApi;

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

    // Lister les pipelines
    public async Task<List<BuildDefinitionReference>> GetPipelinesAsync(string project)
    {
      var connection = new VssConnection(new Uri(_organizationUrl), new VssBasicCredential(string.Empty, _personalAccessToken));
      var buildClient = await connection.GetClientAsync<BuildHttpClient>();

      return await buildClient.GetDefinitionsAsync(project);
    }


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
    }

    public async Task<List<Pipeline>> ListPipelinesAsync(string project)
    {
      var connection = new VssConnection(new Uri(_organizationUrl), new VssBasicCredential(string.Empty, _personalAccessToken));
      var pipelinesClient = await connection.GetClientAsync<PipelinesHttpClient>();

      var pipelines = await pipelinesClient.ListPipelinesAsync(project);
      return pipelines.ToList();
    }
  }
}
