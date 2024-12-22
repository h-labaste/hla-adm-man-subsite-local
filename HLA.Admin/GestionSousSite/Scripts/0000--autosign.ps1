param(
    [Parameter(Mandatory = $true, HelpMessage = "Empreinte numérique (Thumbprint) du certificat à utiliser.")]
    [string]$Thumbprint
)
# $Thumbprint = 045EA4DCADB964B4A0BEF7E92209D8CA323AFDB1 

# Obtenir le certificat à partir de l'empreinte fournie
$thumbprint = $Thumbprint; Get-ChildItem Cert:\CurrentUser\My | Where-Object { $_.Thumbprint -eq $thumbprint } | ForEach-Object { $cert = $_ }; if (-not $cert) { Write-Host "Certificat introuvable" -ForegroundColor Red; exit 1 }; $currentScript = $MyInvocation.MyCommand.Name; Get-ChildItem -Path $PSScriptRoot -Filter "*.ps1" | Where-Object { $_.Name -ne $currentScript -and $_.Name -match '^\d{4}--[a-z0-9\-]+\.ps1$' } | ForEach-Object { try { Set-AuthenticodeSignature -FilePath $_.FullName -Certificate $cert | Out-Null; Write-Host "Script signé : $($_.FullName)" -ForegroundColor Green } catch { Write-Host "Erreur : $($_.FullName) - $_" -ForegroundColor Red } }

# SIG # Begin signature block
# MIIFmQYJKoZIhvcNAQcCoIIFijCCBYYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUG4EPZvDSMxfilgCL4I983o5Y
# zligggMwMIIDLDCCAhSgAwIBAgIQRlDXdAkNT5FI4mHaoB6xNDANBgkqhkiG9w0B
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
# gjcCAQsxDjAMBgorBgEEAYI3AgEVMCMGCSqGSIb3DQEJBDEWBBR1cY0Wli0rkFLx
# YB3wolRVpXkKgDANBgkqhkiG9w0BAQEFAASCAQAb9ohETfTj+c6kUWzEwemll+CY
# fhokZyR9k8bqqUa2i3WffDMLb8ZW8Ju/3eYL8Ie/5VLHbqqe/zFe02sstIe5Xcke
# sQBAqWRAlXdptV/BtOvZxrwkUQvH146rEUDA2zuhVFa029gCRWaraNhOExZRcC+h
# i11MRHtLocsBJXk0kVBg2y5/rhymNecbihPkuWgClnmEVsHXtPno8gxDQdcjgkK6
# QysxNX5R25+za2QQIOlaouJO1JM2RqOZBgpLcyB0L3JtYaZ8GXfYL+WxIqLH473O
# l4jZ4y7PLlKl606z5LshdE4jyA0E6qJ169FHr6mwbWTrgLTpnSdbjXHQvzpZ
# SIG # End signature block
