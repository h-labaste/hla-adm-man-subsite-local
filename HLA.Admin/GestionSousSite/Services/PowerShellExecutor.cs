using System.Diagnostics;
using System.Management.Automation;

namespace GestionSousSite.Services
{
  public interface IPowerShellAdapter
  {
    string ExecuteScript(string scriptPath, Dictionary<string, string> parameters);
  }

  public class PowerShellAutomationAdapter : IPowerShellAdapter
  {
    public string ExecuteScript(string scriptPath, Dictionary<string, string> parameters)
    {
      using (var ps = PowerShell.Create())
      {
        ps.AddCommand(scriptPath);

        foreach (var param in parameters)
        {
          ps.AddParameter(param.Key, param.Value);
        }

        var results = ps.Invoke();

        if (ps.Streams.Error.Count > 0)
        {
          throw new Exception($"Erreur PowerShell : {string.Join(Environment.NewLine, ps.Streams.Error)}");
        }

        return string.Join(Environment.NewLine, results);
      }
    }

    internal static bool TestExecution()
    {
      try
      {
        using (var ps = PowerShell.Create())
        {
          // Teste un script simple pour valider l'exécution
          ps.AddScript("Get-Command Write-Host");
          var results = ps.Invoke();

          // Si aucune erreur n'est levée, System.Management.Automation fonctionne
          return ps.Streams.Error.Count == 0;
        }
      }
      catch
      {
        // Si une exception est levée, considère que System.Management.Automation ne fonctionne pas
        return false;
      }
    }
  }

  public class PowerShellProcessAdapter : IPowerShellAdapter
  {
    public string ExecuteScript(string scriptPath, Dictionary<string, string> parameters)
    {
      var startInfo = new ProcessStartInfo
      {
        FileName = "powershell.exe",
        Arguments = $"-NoProfile -ExecutionPolicy Bypass -File \"{scriptPath}\"",
        RedirectStandardOutput = true,
        RedirectStandardError = true,
        UseShellExecute = false,
        CreateNoWindow = true
      };

      foreach (var param in parameters)
      {
        startInfo.Arguments += $" -{param.Key} \"{param.Value}\"";
      }

      using (var process = Process.Start(startInfo))
      {
        string output = process?.StandardOutput.ReadToEnd() ?? "proceess-no-output";
        string error = process?.StandardError.ReadToEnd() ?? "proceess-no-error";
        process?.WaitForExit();

        if (!string.IsNullOrEmpty(error))
        {
          throw new Exception($"Erreur PowerShell : {error}");
        }

        return output;
      }
    }
    internal static bool TestExecution()
    {
      try
      {
        // Configure le processus pour exécuter une commande simple via powershell.exe
        var startInfo = new ProcessStartInfo
        {
          FileName = "powershell.exe", // Vérifie que powershell.exe est accessible
          Arguments = "-NoProfile -Command \"Write-Host 'Test Execution Successful'\"",
          RedirectStandardOutput = true,
          RedirectStandardError = true,
          UseShellExecute = false,
          CreateNoWindow = true
        };

        using (var process = Process.Start(startInfo))
        {
          if (process == null)
          {
            return false;
          }
          string output = process.StandardOutput.ReadToEnd();
          string error = process.StandardError.ReadToEnd();
          process.WaitForExit();

          // Vérifie si une erreur s'est produite
          if (!string.IsNullOrEmpty(error) || process.ExitCode != 0)
          {
            return false;
          }

          // Vérifie que la sortie contient le texte attendu
          return output.Contains("Test Execution Successful");
        }
      }
      catch
      {
        // Si une exception est levée, considère que powershell.exe ne fonctionne pas
        return false;
      }
    }

  }

  public static class PowerShellAdapterFactory
  {
    public static IPowerShellAdapter Create()
    {
      try
      {
        // Teste si System.Management.Automation est disponible
        Type? powerShellType = Type.GetType("System.Management.Automation.PowerShell, System.Management.Automation");
        if (powerShellType != null)
        {
          // Teste l'exécution avec System.Management.Automation
          if (PowerShellAutomationAdapter.TestExecution())
          {
            return new PowerShellAutomationAdapter();
          }
        }
      }
      catch
      {
        // Ignore l'erreur si le type n'est pas trouvé
      }

      try
      {
        // Si System.Management.Automation n'est pas disponible, utilise powershell.exe
        if (PowerShellProcessAdapter.TestExecution())
        {
          return new PowerShellProcessAdapter();
        }
      }
      catch
      {
        // Ignore l'erreur si le type n'est pas trouvé
      }

      throw new Exception("No Powershell Adapter utilisable");
    }
  }

}
