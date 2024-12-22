using GestionSousSite.Data.Models;

using System.Text.Json;

namespace GestionSousSite.Services
{

  public class PathsService
  {
    private readonly string pathsFile = Path.Combine(Directory.GetCurrentDirectory(), "Config", "paths.perso.json");

    public List<DrivePathInfo> GetPaths()
    {
      if (!File.Exists(pathsFile))
      {
        Console.WriteLine($"Le fichier {pathsFile} est introuvable.");
        return new List<DrivePathInfo>();
      }
      try
      {
        string jsonContent = File.ReadAllText(pathsFile);
        var config = JsonSerializer.Deserialize<DriveConfig>(jsonContent);
        return config?.Drives ?? new List<DrivePathInfo>();
      }
      catch (Exception ex)
      {
        // En cas d'erreur de lecture ou de désérialisation
        Console.WriteLine($"Erreur lors de la lecture du fichier {pathsFile} : {ex.Message}");
        return new List<DrivePathInfo>();
      }
    }
  }

}
