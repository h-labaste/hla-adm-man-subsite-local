namespace GestionSousSite.Data.Models
{
  public class DrivePathInfo
  {
    public required string Name { get; set; }
    public required string Path { get; set; }
    public required string Label { get; set; }
    public required string DnsName { get; set; }
    public required string Project { get; set; }
    public required string Repo { get; set; }
    public string SubDirFormat { get; set; } = "f-*";

    public bool IsConfigured { get => IsSiteConfigured(Path); }

    public bool IsPathExist { get => IsDirExist(Path); }

    public bool IsSiteConfigured(string path)
    {
      // Vérifie si le fichier web.config existe dans le répertoire du site
      return File.Exists(System.IO.Path.Combine(path, "web.config"));
    }
    public bool IsDirExist(string path)
    {
      // Vérifie si le fichier web.config existe dans le répertoire du site
      return Directory.Exists(path);
    }
  }

  public class DriveConfig
  {
    public required List<DrivePathInfo> Drives { get; set; }
  }

}
