using GestionSousSite.Features.Configuration.Components;
using GestionSousSite.Features.Configuration.Models;
using System.Text.RegularExpressions;
using System.Xml.Linq;

namespace GestionSousSite.Features.Configuration.Services
{
  public class ConfigTreeBuilder
  {
    public ConfigNode BuildTree(Dictionary<string, string> appSettings)
    {
      var root = new ConfigNode("Root");

      foreach (var setting in appSettings)
      {
        // Utiliser SplitKeyWithSeparators pour obtenir les segments avec séparateurs
        var pathSegments = SplitKeyWithSeparators(setting.Key);

        // Ajouter les nœuds en passant les segments et la valeur
        AddNodeWithSeparators(root, pathSegments, setting.Value);
      }

      // Fusionner les niveaux contenant un seul élément avant le tri
      // MergeSingleItemLevels(root);

      // Trier les nœuds à chaque niveau
      SortTree(root);

      return root;
    }

    private void AddNodeWithSeparators(ConfigNode parent, List<ConfigNode> segments, string value)
    {
      if (segments == null || segments.Count == 0)
      {
        return;
      }

      // Extraire le premier segment
      var currentSegment = segments[0];

      // Rechercher un nœud enfant avec le même nom et séparateur
      var existingChild = parent.Children.FirstOrDefault(
          child => child.Name == currentSegment.Name && child.Separator == currentSegment.Separator);

      if (existingChild == null)
      {
        // Créer un nouveau nœud si aucun nœud existant ne correspond
        existingChild = new ConfigNode(currentSegment.Name, currentSegment.Separator);
        parent.Children.Add(existingChild);
      }

      // Supprimer le segment traité
      segments.RemoveAt(0);

      if (segments.Count != 0)
      {
        // Continuer avec les segments restants
        AddNodeWithSeparators(existingChild, segments, value);
      }
    }


    private List<string> SplitKey(string paramkey)
    {
      var key = paramkey.Contains("_") ? paramkey : "GLOBAL_" + paramkey;

      // Découper par le premier niveau avec '_'
      var segments = key.Split('_').ToList();
      var result = new List<string>();

      foreach (var segment in segments)
      {
        // Regex ajustée pour capturer correctement des séquences comme D3DS
        var matches = Regex.Matches(segment, @"[A-Z]{2,}(?=\d|[A-Z])|[A-Z][a-z]*|\d+|[A-Z]+");
        string buffer = string.Empty;

        foreach (Match match in matches)
        {
          if (!string.IsNullOrEmpty(buffer))
          {
            // Fusionner si le segment actuel semble être une continuité (comme D3 + DS)
            if (Regex.IsMatch(match.Value, @"^\d") || match.Value.All(char.IsUpper))
            {
              buffer += match.Value;
              continue;
            }
            else
            {
              result.Add(buffer);
              buffer = string.Empty;
            }
          }

          buffer = match.Value;
        }

        if (!string.IsNullOrEmpty(buffer))
        {
          result.Add(buffer);
        }
      }

      // Ajouter la clé entière à la fin pour le contexte complet
      result.Add(paramkey);
      return result;
    }

    private List<ConfigNode> SplitKeyWithSeparators(string paramkey)
    {
      var key = paramkey.Contains("_") ? paramkey : "GLOBAL_" + paramkey;

      // Découper par le premier niveau avec '_'
      var segments = key.Split('_');
      var result = new List<ConfigNode>();

      foreach (var segment in segments)
      {
        // Regex ajustée pour capturer correctement des séquences comme D3DS
        var matches = Regex.Matches(segment, @"[A-Z]+(?=\d|[A-Z])|[A-Z][a-z]*|\d+|[A-Z]+");
        string buffer = string.Empty;

        foreach (Match match in matches)
        {
          if (!string.IsNullOrEmpty(buffer))
          {
            result.Add(new ConfigNode(buffer)); // Ajouter le segment précédent
            buffer = string.Empty;
          }

          buffer = match.Value;
        }

        if (!string.IsNullOrEmpty(buffer))
        {
          result.Add(new ConfigNode(buffer, "_")); // Ajouter le dernier segment avec un séparateur
        }
      }

      // Supprimer le séparateur du dernier segment
      if (result.Count > 0)
      {
        result[^1].Separator = string.Empty;
      }

      return result;
    }


    private ConfigNode MergeSingleItemLevels(ConfigNode node)
    {
      if (node.Children == null || node.Children.Count == 0)
      {
        return node; // Aucun enfant, pas de fusion possible
      }

      while (node.Children.Count == 1 && node.Children.First().Value == null)
      {
        var onlyChild = node.Children.First();

        // Vérifier si le nœud enfant n'est pas une valeur complète
        if (onlyChild.Children.Count > 0)
        {
          // Fusionner le nom du parent avec l'enfant
          node.Name += onlyChild.Separator + onlyChild.Name;
          node.Children = onlyChild.Children;
        }
        else
        {
          break; // Arrêter la fusion si l'enfant est une valeur
        }
      }

      // Appliquer récursivement la fusion aux sous-niveaux
      foreach (var child in node.Children)
      {
        MergeSingleItemLevels(child);
      }

      return node;
    }




    //private ConfigNode MergeSingleItemLevels(ConfigNode node)
    //{
    //  if (node.Children == null || node.Children.Count == 0)
    //  {
    //    return node; // Aucun enfant, pas de fusion possible
    //  }

    //  while (node.Children.Count == 1 && node.Value == null)
    //  {
    //    var onlyChild = node.Children.First();

    //    // Vérifier si le nœud enfant n'est pas une valeur complète
    //    if (onlyChild.Children.Count > 0)
    //    {
    //      // Fusionner le nom du parent avec l'enfant
    //      node.Name += onlyChild.Separator + onlyChild.Name;
    //      node.Children = onlyChild.Children;
    //    }
    //    else
    //    {
    //      break; // Arrêter la fusion si l'enfant est une valeur
    //    }
    //  }

    //  // Appliquer récursivement la fusion aux sous-niveaux
    //  foreach (var child in node.Children)
    //  {
    //    MergeSingleItemLevels(child);
    //  }

    //  return node;
    //}



    private string ReconstructKey(ConfigNode node)
    {
      var parts = new List<string> { node.Name };

      foreach (var child in node.Children)
      {
        parts.Add(ReconstructKey(child));
      }

      return string.Join("", parts);
    }





    private void SortTree(ConfigNode node)
    {
      node.Children = node.Children.OrderBy(c => c.Name).ToList();
      foreach (var child in node.Children)
      {
        SortTree(child); // Appliquer récursivement le tri
      }
    }


    private void AddNode(ConfigNode parent, List<string> segments, string value)
    {
      if (!segments.Any())
      {
        return;
      }

      var currentSegment = segments[0];
      var childNode = parent.Children.FirstOrDefault(c => c.Name == currentSegment);

      if (childNode == null)
      {
        childNode = new ConfigNode(currentSegment);
        parent.Children.Add(childNode);
      }

      if (segments.Count == 1)
      {
        childNode.Value = value; // Dernier segment, ajoutez la valeur
      }
      else
      {
        AddNode(childNode, segments.Skip(1).ToList(), value);
      }
    }
  }

}
