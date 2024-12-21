Param(
    [string]$WebConfigPath
)

# Vérification du chemin du fichier web.config
if (-not (Test-Path -Path $WebConfigPath)) {
    Write-Host "Erreur : Le fichier $WebConfigPath est introuvable."
    exit 1
}

try {
    # Charger le fichier web.config
    [xml]$config = Get-Content $WebConfigPath
    $rewriteRules = $config.configuration.'system.webServer'.rewrite.rules

    if ($rewriteRules -and $rewriteRules.rule) {
        Write-Host "Liste des règles de réécriture :"
        foreach ($rule in $rewriteRules.rule) {
            $ruleName = $rule.GetAttribute("name")
            $matchUrl = $rule.match.GetAttribute("url")
            $conditions = @()
            if ($rule.conditions -and $rule.conditions.add) {
                foreach ($condition in $rule.conditions.add) {
                    $conditions += $condition.GetAttribute("pattern")
                }
            }
            Write-Host "Règle : $ruleName"
            Write-Host "  Match URL : $matchUrl"
            Write-Host "  Conditions : $($conditions -join ', ')"
            Write-Host ""
        }
    } else {
        Write-Host "Aucune règle de réécriture trouvée dans le fichier $WebConfigPath."
    }
} catch {
    Write-Host "Erreur lors de la lecture du fichier $WebConfigPath : $_"
    exit 1
}

Write-Host "Script terminé avec succès."
exit 0
