using GestionSousSite.Data.Models;

namespace GestionSousSite.Features.Sites.Models
{

  public class SousSite
  {
    public required string Name { get; set; }
    public DrivePathInfo? Drive { get; internal set; }
    public required string SubPath { get; set; }
    public required string SubDnsName { get; set; }
    public bool SubIsConfigured { get; set; } // Indique si le sous-site est configuré
    public string SubDirName { get; internal set; } = "f-*";
  }
}
