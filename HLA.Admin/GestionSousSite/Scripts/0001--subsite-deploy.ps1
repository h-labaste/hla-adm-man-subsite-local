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

# SIG # Begin signature block
# MIIFmQYJKoZIhvcNAQcCoIIFijCCBYYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUFU52Vvf2xqf2TYmnqmIHsDIK
# ofegggMwMIIDLDCCAhSgAwIBAgIQRlDXdAkNT5FI4mHaoB6xNDANBgkqhkiG9w0B
# AQsFADAeMRwwGgYDVQQDDBNQb3dlclNoZWxsTG9jYWxDZXJ0MB4XDTI0MTIyMjA5
# MDIyNloXDTI1MTIyMjA5MjIyNlowHjEcMBoGA1UEAwwTUG93ZXJTaGVsbExvY2Fs
# Q2VydDCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAJ5ggdePsdLs3fnD
# h3z1Eg/zNsr4VY8uGQ5wOZMbSpzMjR6tqN6yWZFOhD6g0KhFdHwactfUnqX49bz9
# /ymGEafw+OS6srjWD6c6AerZlzGyeMSpTocHos+5kgPE6FphJGOpS1lpBqpyz9XI
# QUnnPjjV/TAIxxj+UVYNWN9TQRVgkoTf7Zou6xnBuP0ngWMCljq85TdezewRwjVM
# kmuhfG7EHKo+Aki6yhZBoV0MEb7GaL15E+WF74bJg4FL+wSEHnNYJ+WAo7G4MuOB
# mwzpbJbFq4SDDvXX6MFuPJMRnxvbdS4NBpdw2WVm54RwIMlWthImKtXGVIVSF1KV
# 4JNB0c0CAwEAAaNmMGQwDgYDVR0PAQH/BAQDAgeAMBMGA1UdJQQMMAoGCCsGAQUF
# BwMDMB4GA1UdEQQXMBWCE1Bvd2VyU2hlbGxMb2NhbENlcnQwHQYDVR0OBBYEFDCv
# QWoz7gjwEp+ozmCts8FN/Zs/MA0GCSqGSIb3DQEBCwUAA4IBAQBEOryIYYWHCqxg
# BtdfVZpBlyjjM+3OFM0piIzYLsaxTuxsznp8yplw2gALb7yHiX5qpHyUPFevvsth
# s3pBEx91ax9NPT5yqVSdftgwIEP0dpD3M7Warso0In8bWk4QaM/JMiz15NfAChQm
# Y79G+8DlmqjvvWSa12YdWsKdIc4xh0a+IYFCYdE1V12Cfyfoke0Yr6VwZBqau9Dq
# 6/wKrbeoC+CanvOeiwJbpU3IH8wS5TPjJcZVpM2K21xSa/4yIclbCX2TPsuj86IK
# Vq134T5ZmoaINsYM6Syubm6etUlBs+8cc0mFA0X8Qwb0z39OkymLpzg3k/CqNCeH
# vFizUutzMYIB0zCCAc8CAQEwMjAeMRwwGgYDVQQDDBNQb3dlclNoZWxsTG9jYWxD
# ZXJ0AhBGUNd0CQ1PkUjiYdqgHrE0MAkGBSsOAwIaBQCgeDAYBgorBgEEAYI3AgEM
# MQowCKACgAChAoAAMBkGCSqGSIb3DQEJAzEMBgorBgEEAYI3AgEEMBwGCisGAQQB
# gjcCAQsxDjAMBgorBgEEAYI3AgEVMCMGCSqGSIb3DQEJBDEWBBRqTArcd2pKh99D
# zVGFPv9KkJMDQjANBgkqhkiG9w0BAQEFAASCAQBQxkH7LQqe7ftDkde8S+WcWDGC
# nJS4tdKsiJiD6RHl67IT/qDToYkDPlAlgEMuQoAytak1ptTPo6FaCJ7zUfgBmzgL
# l1H+/BwO7m6+kyhQUc7cVoo0Uj1yUTBkf9ehbSIfM7ZZDxiVdxVtiz/OCfDjHmJ+
# wCwoasLM98kTi6YwfrSVBUK36oI802rJYOTF4j4d+oFVrYETwHbREpyqiYh2V+3D
# vdh4hetL/w2+aBIJ527zaLBatVTmTgOXeGC05DxSKoU3ptMBuZlmeSiizIYJof74
# zKHHFtKWG4KHSSFafHI7efRLyXi77D10Rz4bJ1kyIyqszy09QKugjeqml8/H
# SIG # End signature block
