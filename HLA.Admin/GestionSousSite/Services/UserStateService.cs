using GestionSousSite.Data.Models;

public class UserStateService
{
  public event Action? OnStateChange;

  private DrivePathInfo? _selectedDrive;

  public UserStateService()
  {

  }

  public DrivePathInfo? SelectedDrive
  {
    get => _selectedDrive;
    private set
    {
      _selectedDrive = value;
      NotifyStateChanged();
    }
  }

  public void SetSelectedDrive(DrivePathInfo drive)
  {
    SelectedDrive = drive;
  }

  public void Reset()
  {
    SelectedDrive = null;
  }

  private void NotifyStateChanged() => OnStateChange?.Invoke();
}

