Param(
    [string]$ComputerName,  # Nom ou IP du serveur IIS
    [string]$SiteName,      # Nom du site IIS
    [string]$HostName,      # Nom d'hôte (ex : bidule.dev.mon-domain.com)
    [string]$Protocol = "http", # Protocole (http/https)
    [int]$Port = 80,         # Port (par défaut : 80)
    [int]$CertValidityYears = 1, # Durée de validité du certificat
    [string]$CertThumbprint = "" # Empreinte du certificat wildcard existant
)

# Créer une session distante avec le serveur IIS
$session = New-PSSession -ComputerName $ComputerName -Authentication Default

# Script à exécuter à distance
$remoteScript = {
    param($SiteName, $HostName, $Protocol, $Port, $CertValidityYears, $CertThumbprint)

    Import-Module IISAdministration

    # Construire la chaîne de BindingInformation
    $bindingInformation = "*:$Port`:$HostName"

    # Gérer le certificat wildcard
    $certStorePath = "Cert:\LocalMachine\My"
    $cert = $null

    # Si une empreinte est fournie, utiliser le certificat existant
    if ($CertThumbprint -ne "") {
        $cert = Get-ChildItem -Path $certStorePath | Where-Object { $_.Thumbprint -eq $CertThumbprint }
        if (-not $cert) {
            Write-Output "Erreur : Aucun certificat correspondant à l'empreinte $CertThumbprint trouvé."
            exit 1
        }
        Write-Output "Certificat wildcard existant trouvé et utilisé."
    } elseif ($Protocol -eq "https") {
        # Si aucune empreinte n'est fournie, créer un certificat spécifique
        $cert = New-SelfSignedCertificate -DnsName $HostName -CertStoreLocation $certStorePath -NotAfter (Get-Date).AddYears($CertValidityYears) -FriendlyName "Certificat pour ${HostName}"
        Write-Output "Certificat créé pour $HostName."
    }

    # Vérifie si la liaison existe déjà
    $existingBinding = Get-IISSite | Where-Object { $_.Name -eq $SiteName } |
                       ForEach-Object { $_.Bindings | Where-Object { $_.BindingInformation -eq $bindingInformation } }

    if ($existingBinding) {
        Write-Output "La liaison pour $HostName sur $SiteName existe déjà."
    } else {
        # Ajouter la liaison
        if ($Protocol -eq "https" -and $cert -ne $null) {
            New-IISSiteBinding -Name $SiteName -BindingInformation $bindingInformation -Protocol $Protocol -CertificateThumbprint $cert.Thumbprint -CertificateStoreName "My"
            Write-Output "Liaison HTTPS ajoutée : ${HostName} -> ${SiteName} (${Protocol}:${Port})"
        } else {
            New-IISSiteBinding -Name $SiteName -BindingInformation $bindingInformation -Protocol $Protocol
            Write-Output "Liaison HTTP ajoutée : ${HostName} -> ${SiteName} (${Protocol}:${Port})"
        }
    }
}

# Exécuter le script à distance
Invoke-Command -Session $session -ScriptBlock $remoteScript -ArgumentList $SiteName, $HostName, $Protocol, $Port, $CertValidityYears, $CertThumbprint

# Fermer la session distante
Remove-PSSession -Session $session

# SIG # Begin signature block
# MIIFmQYJKoZIhvcNAQcCoIIFijCCBYYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU67TQfvS145wHazYJCP0LgTuZ
# kjOgggMwMIIDLDCCAhSgAwIBAgIQRlDXdAkNT5FI4mHaoB6xNDANBgkqhkiG9w0B
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
# gjcCAQsxDjAMBgorBgEEAYI3AgEVMCMGCSqGSIb3DQEJBDEWBBScksIWrOnklP/g
# UqXMIgXudlqIkDANBgkqhkiG9w0BAQEFAASCAQBhClufom7J/25sigMsoxXNiloO
# /aDAOVbfDULmZYmIj1khaZ+efc7M+i+X0U74jX+ib+ECbaEErpHaiaZB1VrJATr0
# rT2ou97R8ShIInSg5sdcm47xUEqOevN0Lzf5au8acXZNEK2ee0IAelVrnG3VdBDH
# cyLRKeCcx7AvSjOiFQG+JT1LIXjHHaGm1BPIcfcYAYpwFaQcoQCZL8dlOnnG4lBc
# BSbkQ9qbLhWCmjin7Wuy1G50QRxW3xCwbLGo9p0BFLApaS51Ye8DL0eiqesFHZT3
# Vx1pYlN86smKKj0t7TNXSkm4EQZMcNODNcLoKaznQMI7chjwELul27ovasK5
# SIG # End signature block
