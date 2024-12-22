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

# SIG # Begin signature block
# MIIFmQYJKoZIhvcNAQcCoIIFijCCBYYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUTYahsWA/0NapU1bkBjsAZOPV
# zY6gggMwMIIDLDCCAhSgAwIBAgIQRlDXdAkNT5FI4mHaoB6xNDANBgkqhkiG9w0B
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
# gjcCAQsxDjAMBgorBgEEAYI3AgEVMCMGCSqGSIb3DQEJBDEWBBTlJ7PiGawkrp4Z
# GiZUSLSZw/eXxzANBgkqhkiG9w0BAQEFAASCAQADzFhgxvhg5T1GODBrh4jpzcS6
# oI1yO1/yNJP+scg7x0mUaBz7NL1lY/fqPovyUJU0viVlQeGv6+AgoB0xgQnL+93i
# xrF0zmD+keFGFzJ0Iig0WOyy7Te62mcSL7owXKG9GdP1J/eBK8l15PpZeaZJGPI/
# s5M049i0AwCi6tTZw1MiuIaGDSBIRf7/sVRbKOH9DOpRuUn+HoabaPEw6lcl+Bhk
# wqNe7yosvim2pSDeocL33I+tT/AoEpYw4WGtmcER1kUm0xhNAza7d0fhZRN8vLvM
# DCz8fr1FrCg/NKBYHtJ4iPRD2KCacpNvtYBCJzCNZVLRwqgbG/f5iNDkD6S2
# SIG # End signature block
