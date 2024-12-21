namespace GestionSousSite.Features.Configuration.Services
{
  using GestionSousSite.Features.Configuration.Models;

  using System.Data;
  using System.Xml.Linq;

  public class RewriteRulesService
  {
    public List<RewriteRule> GetRewriteRules(string webConfigPath)
    {
      var rules = new List<RewriteRule>();

      if (!File.Exists(webConfigPath))
      {
        throw new FileNotFoundException($"Le fichier {webConfigPath} est introuvable.");
      }

      var configXml = XDocument.Load(webConfigPath);
      var rulesNodes = configXml.Descendants("rule");

      foreach (var ruleNode in rulesNodes)
      {
        var name = ruleNode.Attribute("name")?.Value ?? string.Empty;
        var matchUrl = ruleNode.Element("match")?.Attribute("url")?.Value ?? ".*";
        var conditions = ruleNode.Element("conditions")?.Elements("add").Select(c => new RewriteCondition
        {
          Input = c.Attribute("input")?.Value ?? string.Empty,
          Pattern = c.Attribute("pattern")?.Value ?? string.Empty,
          Negate = c.Attribute("negate")?.Value == "true"
        }).ToList() ?? new List<RewriteCondition>();

        var actionType = ruleNode.Element("action")?.Attribute("type")?.Value ?? "Rewrite";
        var actionUrl = ruleNode.Element("action")?.Attribute("url")?.Value ?? string.Empty;

        rules.Add(new RewriteRule
        {
          Name = name,
          MatchUrl = matchUrl,
          Conditions = conditions,
          ActionType = actionType,
          ActionUrl = actionUrl
        });
      }

      return rules;
    }


    public void AddOrUpdateRewriteRule(string webConfigPath, RewriteRule rule)
    {
      // Charger le fichier web.config
      XDocument config;
      try
      {
        config = XDocument.Load(webConfigPath);
      }
      catch (Exception ex)
      {
        throw new InvalidOperationException($"Erreur lors du chargement du fichier web.config : {ex.Message}");
      }

      // Accéder à la section <rewrite>
      XElement? rewriteSection = config.Root?.Element("system.webServer")?.Element("rewrite");
      if (rewriteSection == null)
      {
        // Créer la section <rewrite> si elle n'existe pas
        XElement systemWebServer = config.Root?.Element("system.webServer") ?? new XElement("system.webServer");
        rewriteSection = new XElement("rewrite", new XElement("rules"));
        systemWebServer.Add(rewriteSection);

        if (config.Root?.Element("system.webServer") == null)
        {
          config.Root?.Add(systemWebServer);
        }
      }
      if (rewriteSection == null)
      {
        throw new InvalidOperationException($"Erreur La section <rewrite> est introuvable dans le fichier web.config.");
      }
        // Accéder à la section <rules>
      XElement? rulesSection = rewriteSection.Element("rules");
      if (rulesSection == null)
      {
        // Créer la section <rules> si elle n'existe pas
        rulesSection = new XElement("rules");
        rewriteSection.Add(rulesSection);
      }

      // Vérifier si une règle avec le même nom existe déjà
      XElement? existingRule = rulesSection.Elements("rule").FirstOrDefault(r => r.Attribute("name")?.Value == rule.Name);
      if (existingRule != null)
      {
        // Supprimer l'ancienne règle si elle existe
        existingRule.Remove();
      }

      // Ajouter la nouvelle règle
      XElement newRuleElement = new XElement("rule",
          new XAttribute("name", rule.Name),
          new XAttribute("stopProcessing", "true"),
          new XElement("match", new XAttribute("url", rule.MatchUrl)),
          new XElement("conditions", rule.Conditions.Select(c =>
              new XElement("add",
                  new XAttribute("input", c.Input),
                  new XAttribute("pattern", c.Pattern),
                  new XAttribute("negate", c.Negate.ToString().ToLower())
              ))
          ),
          new XElement("action",
              new XAttribute("type", rule.ActionType),
              new XAttribute("url", rule.ActionUrl)
          )
      );

      rulesSection.Add(newRuleElement);

      // Sauvegarder le fichier web.config
      try
      {
        config.Save(webConfigPath);
      }
      catch (Exception ex)
      {
        throw new InvalidOperationException($"Erreur lors de la sauvegarde du fichier web.config : {ex.Message}");
      }
    }

    public void DeleteRewriteRule(string webConfigPath, string ruleName)
    {
      var configXml = XDocument.Load(webConfigPath);
      var rulesContainer = configXml.Descendants("rules").FirstOrDefault();

      if (rulesContainer == null)
      {
        throw new InvalidOperationException("La section <rules> est introuvable dans le fichier web.config.");
      }

      var ruleToDelete = rulesContainer.Elements("rule").FirstOrDefault(r => r.Attribute("name")?.Value == ruleName);

      if (ruleToDelete != null)
      {
        ruleToDelete.Remove();
        configXml.Save(webConfigPath);
      }
    }
  }

}
