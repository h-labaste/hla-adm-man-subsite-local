# Variables
$sdkVersion = "8"
$runtimeVersion = "8"
$installScriptUrl = "https://dot.net/v1/dotnet-install.ps1"

# Télécharger le script d'installation
Write-Host "Téléchargement du script d'installation .NET..." -ForegroundColor Cyan
Invoke-WebRequest -Uri $installScriptUrl -OutFile "dotnet-install.ps1"

# Installer le SDK .NET
Write-Host "Installation du SDK .NET version $sdkVersion..." -ForegroundColor Cyan
.\dotnet-install.ps1 -Version $sdkVersion

# Installer le Runtime .NET
Write-Host "Installation du Runtime .NET version $runtimeVersion..." -ForegroundColor Cyan
.\dotnet-install.ps1 -Version $runtimeVersion -Runtime dotnet

# Installer le Runtime ASP.NET Core
Write-Host "Installation du Runtime ASP.NET Core version $runtimeVersion..." -ForegroundColor Cyan
.\dotnet-install.ps1 -Version $runtimeVersion -Runtime aspnetcore

Write-Host "Installation terminée avec succès !" -ForegroundColor Green
