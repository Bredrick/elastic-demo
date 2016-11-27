param (
    [string]$version = "5.0.1",
    [string]$target = (Test-Connection "$env:computername" -count 1).IPv4Address.IPAddressToString + ":9200"
 )

$source = "https://artifacts.elastic.co/downloads/logstash/logstash-$version.zip"
$destination = "C:\elk"
$downloadDest = "$destination\logstash-$version.zip"
$configFolder = "$destination\logstash-$version\config"
$jvmOptions = "$configFolder\jvm.options"
$logstashOptions = "$configFolder\logstash.yml"

$client = new-object System.Net.WebClient

Write-Host "Downloading to $downloadDest"

$client.downloadFile($source, $downloadDest)

if (!(Test-Path $downloadDest)) {
    Write-Host "Downloading $downloadDest failed"
    Exit
}

if (!(Test-Path "$destination\logstash-$version")) {
	Write-Host "Extracting $downloadDest"
	Add-Type -AssemblyName System.IO.Compression.FileSystem
	[System.IO.Compression.ZipFile]::ExtractToDirectory( $downloadDest, $destination)
}

Write-Host "Changing $jvmOptions"
(Get-Content $jvmOptions) | Foreach-Object {
    $_ -replace '-Xms256m', '-Xms128m' `
       -replace '-Xmx1g', '-Xmx256m' `
    } | Set-Content $jvmOptions

Write-Host "Changing $logstashOptions"
(Get-Content $logstashOptions) | Foreach-Object {
    $_ -replace '# path.data:', "path.data: $destination\logstash-$version\data" `
       -replace '# path.config:', "path.config: $configFolder\pipeline.conf" `
    } | Set-Content $logstashOptions

Write-Host "Creating $configFolder\pipeline.conf"
Copy-Item .\pipelineTemplate.conf $configFolder\pipeline.conf

(Get-Content $configFolder\pipeline.conf) | Foreach-Object {
    $_ -replace 'hosts => \[ "target" \]', "hosts => [ ""$target"" ]" `
    } | Set-Content $configFolder\pipeline.conf

Write-Host 'Configuring Firewall rules'
Import-Module NetSecurity
New-NetFirewallRule -Name Logstash_beats -DisplayName “Logstash_beats” `
                    -Protocol TCP -LocalPort "5040-5050" -Enabled True -Profile Any -Action Allow 