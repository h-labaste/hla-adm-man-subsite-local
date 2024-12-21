Param(
    [string]$SubdomainName,
    [string]$SubdomainPath,
    [string]$WebConfigPath
)

if (Test-Path -Path $SubdomainPath) {
    Remove-Item -Recurse -Force -Path $SubdomainPath
    Write-Host "Dossier supprimé : $SubdomainPath"
}

[xml]$config = Get-Content $WebConfigPath
$rewriteRules = $config.configuration.'system.webServer'.rewrite.rules
$rule = $rewriteRules.rule | Where-Object { $_.name -eq "Redirect $SubdomainName" }
if ($rule) {
    $rewriteRules.RemoveChild($rule) | Out-Null
    $config.Save($WebConfigPath)
    Write-Host "Règle supprimée pour $SubdomainName."
}

Write-Host "Script terminé."
