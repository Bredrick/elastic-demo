param (
    [Parameter(Mandatory=$true)][string]$type,
    [string]$version = "5.0.1",
    [string]$target = "localhost:5044"
 )

$availableTypes = @("file", "metric")
if (!$availableTypes.Contains($type)) {
    $ofs = ' or '
    Write-Host "Wrong type. Allowed only $availableTypes."
    Exit
}

$beat = $type + "beat"

$source = "https://artifacts.elastic.co/downloads/beats/$beat/$beat-$version-windows-x86_64.zip"
$destination = "C:\app"
$downloadDest = "$destination\$beat-$version.zip"
$options = "$destination\$beat-$version-windows-x86_64\$beat.yml"

$client = new-object System.Net.WebClient

Write-Host "Downloading to $downloadDest"
$client.downloadFile($source, $downloadDest)

if (!(Test-Path $downloadDest)) {
    Write-Host "Downloading $downloadDest failed"
    Exit
}

if (!(Test-Path "$destination\$beat-$version-windows-x86_64")) {
	Write-Host "Extracting $downloadDest"
	Add-Type -AssemblyName System.IO.Compression.FileSystem
	[System.IO.Compression.ZipFile]::ExtractToDirectory($downloadDest, $destination)
}

Write-Host "Changing $options"
switch ($beat) {
    "filebeat" {
        (Get-Content $options) | Foreach-Object {
            $_ -replace '- /var/log/*.log', '#- /var/log/*.log' `
               -replace "#- c:\\programdata\\elasticsearch\\logs\\", "- c:\app\logs\" `
               -replace 'hosts: \["localhost:9200"\]', "#hosts: [""localhost:9200""]" `
               -replace '#hosts: \["localhost:5044"\]', "hosts: [""$target""]" `
               -replace 'output.elasticsearch:', "#output.elasticsearch:" `
               -replace '#output.logstash:', "output.logstash:" `
            } | Set-Content $options
        break
    }
    "metricbeat" {
        (Get-Content $options) | Foreach-Object {
            $_ -replace 'hosts: \["localhost:9200"\]', "#hosts: [""localhost:9200""]" `
               -replace '#hosts: \["localhost:5044"\]', "hosts: [""$target""]" `
               -replace '- process', "#- process" `
               -replace 'output.elasticsearch:', "#output.elasticsearch:" `
               -replace '#output.logstash:', "output.logstash:" `
            } | Set-Content $options
        break
    }
}

Write-Host "Installing service $beat"
invoke-expression -Command $destination\$beat-$version-windows-x86_64\install-service-$beat.ps1

Write-Host "Starting service $beat"
Start-Service $beat