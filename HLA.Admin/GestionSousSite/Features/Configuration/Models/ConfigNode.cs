namespace GestionSousSite.Features.Configuration.Models
{
  public class ConfigNode
  {
    public string Name { get; set; } = string.Empty; 
    public string Separator { get; set; } = string.Empty; // Séparateur utilisé pour ce segment

    public string? Value { get; set; } // Si c'est un nœud feuille
    public List<ConfigNode> Children { get; set; } = new();

    public bool HasChildren => Children.Any();

    public ConfigNode(string name = "", string separator = "")
    {
      Name = name;
      Separator = separator;
    }
  }
}
