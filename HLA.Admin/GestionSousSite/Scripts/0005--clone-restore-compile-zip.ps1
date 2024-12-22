Param(
    [string]$RepositoryUrl,         # URL du dépôt Git
    [string]$BranchName = "master", # Branche à cloner
    [string]$TargetPath,            # Chemin où cloner le dépôt
    [string]$SolutionFile,          # Nom de la solution à construire
    [string]$OutputDirectory,       # Répertoire pour les artefacts
    [string]$ZipPath,               # Chemin du fichier ZIP final
    [string]$GitToken = $null       # Jeton d'accès personnel (PAT) facultatif
)

# Fonction pour afficher les messages d'erreur
function Show-Error {
    Param([string]$Message)
    Write-Host "ERROR: $Message" -ForegroundColor Red
    exit 1
}

# Fonction pour vérifier l'authentification Git
function Check-GitAuthentication {
    Write-Host "Vérification de l'authentification Git..."
    try {
        if ($GitToken) {
            # Ajouter le token dans l'URL si fourni
            $authUrl = $RepositoryUrl -replace 'https://', "https://:$GitToken@"
            git ls-remote $authUrl > $null 2>&1
        } else {
            git ls-remote $RepositoryUrl > $null 2>&1
        }

        if ($LASTEXITCODE -ne 0) {
            if ($GitToken) {
                Show-Error "Échec de l'accès au dépôt Git avec le token. Vérifiez vos informations d'identification."
            } else {
                Show-Error "Échec de l'accès au dépôt Git sans token. Fournissez un jeton d'accès personnel (PAT)."
            }
        }
    } catch {
        Show-Error "Erreur lors de la vérification de l'accès au dépôt : $_"
    }
}

# 1. Vérifier l'accès au dépôt
Check-GitAuthentication

# 2. Cloner ou mettre à jour le dépôt
Write-Host "Clonage ou mise à jour du dépôt $RepositoryUrl (branche $BranchName)..."
if (!(Test-Path -Path $TargetPath)) {
    if ($GitToken) {
        $authUrl = $RepositoryUrl -replace 'https://', "https://:$GitToken@"
        git clone --branch $BranchName $authUrl $TargetPath
    } else {
        git clone --branch $BranchName $RepositoryUrl $TargetPath
    }

    if ($LASTEXITCODE -ne 0) {
        Show-Error "Échec du clonage du dépôt."
    }
} else {
    Push-Location $TargetPath
    git fetch origin
    if ($LASTEXITCODE -ne 0) {
        Show-Error "Échec de la récupération des mises à jour."
    }
    git checkout $BranchName
    if ($LASTEXITCODE -ne 0) {
        Show-Error "Impossible de changer de branche."
    }
    Pop-Location
}

# 3. Restaurer les dépendances NuGet
Write-Host "Restauration des dépendances NuGet..."
Push-Location $TargetPath
dotnet restore $SolutionFile
if ($LASTEXITCODE -ne 0) {
    Show-Error "Échec de la restauration des dépendances."
}
Pop-Location

# 4. Construire la solution
Write-Host "Construction de la solution $SolutionFile..."
$BuildOutputPath = Join-Path $OutputDirectory "build"
if (!(Test-Path -Path $BuildOutputPath)) {
    New-Item -ItemType Directory -Path $BuildOutputPath -Force
}
dotnet build $SolutionFile -c Release -o $BuildOutputPath
if ($LASTEXITCODE -ne 0) {
    Show-Error "Échec de la construction de la solution."
}

# 5. Générer un ZIP des artefacts
Write-Host "Génération du fichier ZIP des artefacts..."
if (!(Test-Path -Path $OutputDirectory)) {
    New-Item -ItemType Directory -Path $OutputDirectory -Force
}
$FilesToZip = Join-Path $BuildOutputPath "*"
Compress-Archive -Path $FilesToZip -DestinationPath $ZipPath -Force
if ($LASTEXITCODE -ne 0) {
    Show-Error "Échec de la compression en ZIP."
}

Write-Host "Le fichier ZIP des artefacts a été généré avec succès : $ZipPath" -ForegroundColor Green
