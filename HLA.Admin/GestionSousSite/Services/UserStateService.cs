using GestionSousSite.Data.Models;

public class UserStateService
{
    // Stocker le Drive sélectionné pour l'utilisateur
    public DrivePathInfo? SelectedDrive { get; private set; }

    // Méthode pour définir le Drive sélectionné
    public void SetSelectedDrive(DrivePathInfo drive)
    {
        SelectedDrive = drive;
    }

    // Méthode pour réinitialiser l'état
    public void Reset()
    {
        SelectedDrive = null;
    }
}
