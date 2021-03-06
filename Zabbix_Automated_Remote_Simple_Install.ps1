#
# THIS SCRIPT IS READY TO USE
#

# Short description of script
# THIS IS USED FOR PUSHING ZABBIX AGENTS TO REMOTE IP ADDRESSES
# Installs the Zabbix agent if not installed
# This script will be using private Github repositories for maintaining the files
#
# CSV file must be as following:
# Name
# ServerNameOne
# ServerNameTwo
# ServerNameThree

# VERSION 1.1

function Choice1

{


#Gets the server host name
$serverHostname =  Invoke-Command -ScriptBlock {hostname}


# Creates Zabbix DIR
mkdir c:\zabbix


# Downloads version 5.0.0 from https://www.zabbix.com/download_agents
Invoke-WebRequest "https://www.zabbix.com/downloads/5.0.0/zabbix_agent-5.0.0-windows-amd64-openssl.zip" -outfile c:\zabbix\zabbix.zip

Add-Type -AssemblyName System.IO.Compression.FileSystem
function Unzip
{
    param([string]$zipfile, [string]$outpath)

    [System.IO.Compression.ZipFile]::ExtractToDirectory($zipfile, $outpath)
}

# Unzipping file to c:\zabbix
Unzip "c:\Zabbix\zabbix.zip" "c:\zabbix"      


# Sorts files in c:\zabbix
Move-Item c:\zabbix\bin\zabbix_agentd.exe -Destination c:\zabbix


# Sorts files in c:\zabbix
Move-Item c:\zabbix\conf\zabbix_agentd.conf -Destination c:\zabbix

# Replaces 127.0.0.1 with your Zabbix server IP in the config file
# You need to change the ip address 192.168.5.2 with your own
(Get-Content -Path c:\zabbix\zabbix_agentd.conf) | ForEach-Object {$_ -Replace '127.0.0.1', "192.168.5.2"} | Set-Content -Path c:\zabbix\zabbix_agentd.conf

# Replaces hostname in the config file
(Get-Content -Path c:\zabbix\zabbix_agentd.conf) | ForEach-Object {$_ -Replace 'Windows host', "$ServerHostname"} | Set-Content -Path c:\zabbix\zabbix_agentd.conf

# Attempts to install the agent with the config in c:\zabbix
c:\zabbix\zabbix_agentd.exe --config c:\zabbix\zabbix_agentd.conf --install

# Attempts to start the agent
c:\zabbix\zabbix_agentd.exe --start

# Creates a firewall rule for the Zabbix server
New-NetFirewallRule -DisplayName "Allow Zabbix communication" -Direction Inbound -Program "c:\zabbix\zabbix_agentd.exe" -RemoteAddress LocalSubnet -Action Allow

}




# Username and Password used for Windows Authentication
$Username = Read-Host 'What is your domain + Username?'
$Password = Read-Host 'What is your password?'
$SecurePassword = ConvertTo-SecureString -String $Password -asPlainText -Force
$Credential = New-Object System.Management.Automation.PSCredential($Username,$SecurePassword)

# Asks the user for CSV file path. Example: C:\Foldername\Filename.csv
$filepath = Read-Host 'Please enter your filepath for CSV file. Example: C:\Foldername\Filename.csv'


$ServerList = Import-CSV $filepath

ForEach ($Server in $ServerList) 

{
    Invoke-Command -ComputerName $Server.Name ` -ScriptBlock ${Function:Choice1} ` -credential $Credential
}