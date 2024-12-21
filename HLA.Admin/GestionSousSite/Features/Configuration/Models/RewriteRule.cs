namespace GestionSousSite.Features.Configuration.Models
{
  public class RewriteCondition
  {
    /// <summary>
    /// Spécifie la condition d'entrée, par exemple {HTTP_HOST}.
    /// </summary>
    public string Input { get; set; } = "{HTTP_HOST}";

    /// <summary>
    /// Spécifie le motif à matcher, par exemple ^example.com$.
    /// </summary>
    public string Pattern { get; set; } = string.Empty;

    /// <summary>
    /// Indique si la condition doit être négative (par exemple, ne correspond pas au modèle).
    /// </summary>
    public bool Negate { get; set; } = false;
  }

  public class RewriteRule
  {
    /// <summary>
    /// Le nom de la règle.
    /// </summary>
    public string Name { get; set; } = string.Empty;

    /// <summary>
    /// L'URL à matcher pour cette règle.
    /// </summary>
    public string MatchUrl { get; set; } = ".*";

    /// <summary>
    /// Liste des conditions à appliquer à la règle.
    /// </summary>
    public List<RewriteCondition> Conditions { get; set; } = new List<RewriteCondition>();

    /// <summary>
    /// Le type d'action à appliquer (par exemple, "Rewrite" ou "Redirect").
    /// </summary>
    public string ActionType { get; set; } = "Rewrite";

    /// <summary>
    /// L'URL cible de l'action.
    /// </summary>
    public string ActionUrl { get; set; } = string.Empty;
  }


}
