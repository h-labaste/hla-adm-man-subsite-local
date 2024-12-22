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

# SIG # Begin signature block
# MIIFmQYJKoZIhvcNAQcCoIIFijCCBYYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUJKF7llGhHsx8Bc0NfFAB8lqo
# k4OgggMwMIIDLDCCAhSgAwIBAgIQRlDXdAkNT5FI4mHaoB6xNDANBgkqhkiG9w0B
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
# gjcCAQsxDjAMBgorBgEEAYI3AgEVMCMGCSqGSIb3DQEJBDEWBBRzJkdZ6GHkyA9M
# TfKcNqjGQmjtGTANBgkqhkiG9w0BAQEFAASCAQCWb7+opeaw4T+YCYbJJMBjUNvN
# jLFnoqrnhyip0Ed0NBQLZhIymaOFMz3hevn4tLWjkqTJIOfBmlwjxXYzFfuqpHLh
# xQfeAFZbuTPJSERM0UDiKJbgyrr75bq0b8KNtqN7OxYglsN+KXfBEV2FkMbr547D
# s90v7mI8u91Gj2SeOdER271ISwV2d5ua3lNuxGLXXgFIVuqRvHHtt121Yyjq7rBG
# govL9D+qQWnVK/KuDoHh90HMU1pjqqnkegBOKJwrzJSJX9EcA0ugSt4nJgPMXhYM
# lkwtfuPwSerlOssQe+gWXIyxZh/ELrJyiehtktMF41+qGZaf/mOtjXgGcwVj
# SIG # End signature block
