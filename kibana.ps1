param (
    [string]$version = "5.0.1",
    [string]$target = (Test-Connection "$env:computername" -count 1).IPv4Address.IPAddressToString + ":9200"
 )

$source = "https://artifacts.elastic.co/downloads/kibana/kibana-$version-windows-x86.zip"
$destination = "C:\elk"
$downloadDest = "$destination\kibana-$version.zip"
$configFolder = "$destination\kibana-$version-windows-x86\config"
$kibanaOptions = "$configFolder\kibana.yml"

$client = new-object System.Net.WebClient

Write-Host "Downloading to $downloadDest"

$client.downloadFile($source, $downloadDest)

if (!(Test-Path $downloadDest)) {
    Write-Host "Downloading $downloadDest failed"
    Exit
}

if (!(Test-Path "$destination\kibana-$version-windows-x86")) {
	Write-Host "Extracting $downloadDest"
	Add-Type -AssemblyName System.IO.Compression.FileSystem
	[System.IO.Compression.ZipFile]::ExtractToDirectory( $downloadDest, $destination)
}

$ip = (Test-Connection "$env:computername" -count 1).IPv4Address.IPAddressToString
Write-Host "Changing $kibanaOptions"
(Get-Content $kibanaOptions) | Foreach-Object {
    $_ -replace '#elasticsearch.url: "http://localhost:9200"', "elasticsearch.url: ""http://$target""" `
       -replace '#server.name: "your-hostname"', "server.name: $ip" `
       -replace '#server.host: "localhost"', "server.host: $ip" `
    } | Set-Content $kibanaOptions

Write-Host 'Configuring Firewall rules'
Import-Module NetSecurity
New-NetFirewallRule -Name Kibana -DisplayName “Kibana” `
                    -Protocol TCP -LocalPort "5601" -Enabled True -Profile Any -Action Allow 