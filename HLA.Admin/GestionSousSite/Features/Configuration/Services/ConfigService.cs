using System.Xml;

using GestionSousSite.Features.Configuration.Models;

namespace GestionSousSite.Features.Configuration.Services
{
  public class ConfigService
  {
    public ConfigService()
    {
    }

    /// <summary>
    /// Lit les appsettings du fichier web.config.
    /// </summary>
    public async Task<Dictionary<string, string>> GetAppSettingsAsync(string webConfigPath)
    {
      return await Task.Run(() => {
        if (!File.Exists(webConfigPath))
        {
          throw new FileNotFoundException($"Le fichier {webConfigPath} est introuvable.");
        }

        var appSettings = new Dictionary<string, string>();
        try
        {
          var xmlDoc = new XmlDocument();
          xmlDoc.Load(webConfigPath);

          var appSettingsNode = xmlDoc.SelectSingleNode("//configuration/appSettings");
          if (appSettingsNode != null)
          {
            XmlNodeList? Nodes = appSettingsNode.SelectNodes("add");
            if (Nodes != null)
            {
              foreach (XmlNode addNode in Nodes)
              {
                var key = addNode.Attributes?["key"]?.Value;
                var value = addNode.Attributes?["value"]?.Value;
                if (!string.IsNullOrEmpty(key))
                {
                  appSettings[key] = value ?? string.Empty;
                }
              }
            }
          }
        }
        catch (Exception ex)
        {
          throw new Exception("Erreur lors de la lecture des appsettings.", ex);
        }

        return appSettings;
      });
    }

    /// <summary>
    /// Lit les règles de réécriture du fichier web.config.
    /// </summary>
    public async Task<List<RewriteRule>> GetRewriteRulesAsync(string webConfigPath)
    {
      return await Task.Run(() => {
        if (!File.Exists(webConfigPath))
        {
          throw new FileNotFoundException($"Le fichier {webConfigPath} est introuvable.");
        }

        var rules = new List<RewriteRule>();
        try
        {
          var xmlDoc = new XmlDocument();
          xmlDoc.Load(webConfigPath);

          var rulesNode = xmlDoc.SelectSingleNode("//configuration/system.webServer/rewrite/rules");
          if (rulesNode != null)
          {
            XmlNodeList? Nodes = rulesNode.SelectNodes("rule");
            if (Nodes != null)
            {
              foreach (XmlNode ruleNode in Nodes)
              {
                var name = ruleNode.Attributes?["name"]?.Value;
                var matchUrl = ruleNode.SelectSingleNode("match")?.Attributes?["url"]?.Value;
                var conditions = new List<RewriteCondition>();

                var conditionsNode = ruleNode.SelectSingleNode("conditions");
                if (conditionsNode != null)
                {
                  XmlNodeList? Nodes2 = conditionsNode.SelectNodes("add");
                  if (Nodes2 != null)
                  {
                    foreach (XmlNode conditionNode in Nodes2)
                    {
                      var pattern = conditionNode.Attributes?["pattern"]?.Value ?? "";
                      var input = conditionNode.Attributes?["input"]?.Value ?? "";
                      var negate = conditionNode.Attributes?["negate"]?.Value ?? "false";
                      if (!string.IsNullOrEmpty(pattern))
                      {
                        conditions.Add(new RewriteCondition { Pattern = pattern, Input = input, Negate = bool.Parse(negate) });
                      }
                    }
                  }
                }

                rules.Add(new RewriteRule
                {
                  Name = name ?? "Sans nom",
                  MatchUrl = matchUrl ?? "Non spécifié",
                  Conditions = conditions
                });
              }
            }
          }
        }
        catch (Exception ex)
        {
          throw new Exception("Erreur lors de la lecture des règles de réécriture.", ex);
        }

        return rules;
      });
    }
  }
}
