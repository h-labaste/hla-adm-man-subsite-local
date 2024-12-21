#!/bin/bash

# Variables
sdkVersion="8"
runtimeVersion="8"
installScriptUrl="https://dot.net/v1/dotnet-install.sh"

# Télécharger le script d'installation
echo "Téléchargement du script d'installation .NET..."
curl -sSL $installScriptUrl -o dotnet-install.sh
chmod +x dotnet-install.sh

# Installer le SDK .NET
echo "Installation du SDK .NET version $sdkVersion..."
./dotnet-install.sh --version $sdkVersion

# Installer le Runtime .NET
echo "Installation du Runtime .NET version $runtimeVersion..."
./dotnet-install.sh --version $runtimeVersion --runtime dotnet

# Installer le Runtime ASP.NET Core
echo "Installation du Runtime ASP.NET Core version $runtimeVersion..."
./dotnet-install.sh --version $runtimeVersion --runtime aspnetcore

echo "Installation terminée avec succès !"
