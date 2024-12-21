Param(
    [string]$SubdomainName,
    [string]$DomainUrl,
    [string]$SubdomainPath,
    [string]$WebConfigPath
)

# Validation des paramètres
if (-not $SubdomainName -or -not $DomainUrl -or -not $SubdomainPath -or -not $WebConfigPath) {
    Write-Host "Erreur : Tous les paramètres doivent être fournis."
    exit 1
}

# Vérification de l'existence du fichier web.config
if (-not (Test-Path -Path $WebConfigPath)) {
    Write-Host "Erreur : Le fichier $WebConfigPath est introuvable."
    exit 1
}

# Création du dossier si nécessaire
if (-not (Test-Path -Path $SubdomainPath)) {
    try {
        New-Item -ItemType Directory -Path $SubdomainPath
        Write-Host "Dossier créé : $SubdomainPath"
    } catch {
        Write-Host "Erreur lors de la création du dossier $SubdomainPath : $_"
        exit 1
    }
}

# Sauvegarde du fichier web.config
try {
    Copy-Item -Path $WebConfigPath -Destination "$WebConfigPath.bak" -Force
    Write-Host "Backup  du fichier web.config effectuée."
} catch {
    Write-Host "Erreur lors de la sauvegarde du fichier web.config : $_"
    exit 1
}

# Modification du fichier web.config
try {
    [xml]$config = Get-Content $WebConfigPath
    $rewriteRules = $config.configuration.'system.webServer'.rewrite.rules

    # Vérification précise de l'existence de la règle
    $existingRule = $rewriteRules.rule | Where-Object {
        $_.name -eq "Redirect $SubdomainName" -and
        $_.match.url -eq ".*" -and
        $_.conditions.add.input -eq "{HTTP_HOST}" -and
        $_.conditions.add.pattern -eq "^$DomainUrl$"
    }

    if (-not $existingRule) {
        $rule = $config.CreateElement("rule")
        $rule.SetAttribute("name", "Redirect $SubdomainName")
        $rule.SetAttribute("stopProcessing", "true")

        $match = $config.CreateElement("match")
        $match.SetAttribute("url", ".*")
        $rule.AppendChild($match) | Out-Null

        $conditions = $config.CreateElement("conditions")
        $condition = $config.CreateElement("add")
        $condition.SetAttribute("input", "{HTTP_HOST}")
        $condition.SetAttribute("pattern", "^$DomainUrl$")
        $conditions.AppendChild($condition) | Out-Null
        $rule.AppendChild($conditions) | Out-Null

        $action = $config.CreateElement("action")
        $action.SetAttribute("type", "Rewrite")
        $action.SetAttribute("url", "/f-$SubdomainName/{R:0}")
        $rule.AppendChild($action) | Out-Null

        $rewriteRules.AppendChild($rule) | Out-Null
        $config.Save($WebConfigPath)
        Write-Host "Nouvelle règle ajoutée pour $SubdomainName."
    } else {
        Write-Host "La règle pour $SubdomainName existe déjà et correspond."
    }
} catch {
    Write-Host "Erreur lors de la modification du fichier $WebConfigPath : $_"
    exit 1
}

Write-Host "Script terminé avec succès."
exit 0
