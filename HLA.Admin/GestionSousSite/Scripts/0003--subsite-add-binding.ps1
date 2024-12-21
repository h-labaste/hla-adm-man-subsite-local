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
