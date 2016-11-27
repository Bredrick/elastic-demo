param (
    [string]$version = "5.0.1",
    [string]$target = (Test-Connection "$env:computername" -count 1).IPv4Address.IPAddressToString + ":9300"
 )

$source = "https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-$version.zip"
$destination = "C:\elk"
$downloadDest = "$destination\elasticsearch-$version.zip"
$configFolder = "$destination\elasticsearch-$version\config"
$jvmOptions = "$configFolder\jvm.options"
$esOptions = "$configFolder\elasticsearch.yml"

$client = new-object System.Net.WebClient

Write-Host "Downloading to $downloadDest"

$client.downloadFile($source, $downloadDest)

if (!(Test-Path $downloadDest)) {
    Write-Host "Downloading $downloadDest failed"
    Exit
}

if (!(Test-Path "$destination\elasticsearch-$version")) {
	Write-Host "Extracting $downloadDest"
	Add-Type -AssemblyName System.IO.Compression.FileSystem
	[System.IO.Compression.ZipFile]::ExtractToDirectory( $downloadDest, $destination)
}

Write-Host "Changing $jvmOptions"
(Get-Content $jvmOptions) | Foreach-Object {
    $_ -replace '-Xms2g', '-Xms512m' `
       -replace '-Xmx2g', '-Xmx512m' `
    } | Set-Content $jvmOptions

$ip = (Test-Connection "$env:computername" -count 1).IPv4Address.IPAddressToString
Write-Host "Changing $esOptions"
(Get-Content $esOptions) | Foreach-Object {
    $_ -replace '#cluster.name: my-application', 'cluster.name: es-test-cluster' `
       -replace '#node.name: node-1', "node.name: $env:computername" `
       -replace '#network.host: 192.168.0.1', "network.host: $ip" `
       -replace '#discovery.zen.ping.unicast.hosts: \["host1", "host2"\]', "
discovery.zen.ping.unicast.hosts: [""$target""]" `
       -replace '#discovery.zen.minimum_master_nodes: 3', "discovery.zen.minimum_master_nodes: 1" `
    } | Set-Content $esOptions

Write-Host 'Configuring Firewall rules'
Import-Module NetSecurity
New-NetFirewallRule -Name Allow_Ping -DisplayName “Allow_Ping” `
                    -Protocol ICMPv4 -IcmpType 8 -Enabled True -Profile Any -Action Allow 
New-NetFirewallRule -Name Elasticsearch -DisplayName “Elasticsearch” `
                    -Protocol TCP -LocalPort "9200-9400" -Enabled True -Profile Any -Action Allow 

Write-Host 'X-pack'
Invoke-Expression "$destination\elasticsearch-$version\bin\elasticsearch-plugin.bat install x-pack"
$disableSecurity = "xpack.security.enabled: false"
echo $disableSecurity | out-file $esOptions -append -encoding utf8
