#based on https://skarlso.github.io/2015/06/30/powershell-can-also-be-nice-or-installing-java-silently-and-waiting/

$JRE_VER="8u112"
$JRE_FULL_VER="8u112-b15"
$JRE_PATH="1.8.0_112"
$source64 = "http://download.oracle.com/otn-pub/java/jdk/$JRE_FULL_VER/jre-$JRE_VER-windows-x64.exe"
$destination64 = "C:\app\$JRE_VER-x64.exe"
$client = new-object System.Net.WebClient
$cookie = "oraclelicense=accept-securebackup-cookie"
$client.Headers.Add([System.Net.HttpRequestHeader]::Cookie, $cookie)
 
Write-Host 'Checking if Java is already installed'
if (Test-Path "c:\Program Files\Java") {
    Write-Host 'No need to Install Java'
    Exit
}
 
Write-Host "Downloading x64 to $destination64"
 
$client.downloadFile($source64, $destination64)
if (!(Test-Path $destination64)) {
    Write-Host "Downloading $destination64 failed"
    Exit
}
 
 
try {
    Write-Host 'Installing JRE-x64'
    $proc1 = Start-Process -FilePath "$destination64" -ArgumentList "/s REBOOT=ReallySuppress" -Wait -PassThru
    $proc1.waitForExit()
    Write-Host 'Installation Done.'
} catch [exception] {
    write-host '$_ is' $_
    write-host '$_.GetType().FullName is' $_.GetType().FullName
    write-host '$_.Exception is' $_.Exception
    write-host '$_.Exception.GetType().FullName is' $_.Exception.GetType().FullName
    write-host '$_.Exception.Message is' $_.Exception.Message
}
 
if (Test-Path "c:\Program Files\Java") {
    Write-Host 'Java installed successfully.'
}
Write-Host 'Setting up Path variables.'
[System.Environment]::SetEnvironmentVariable("JAVA_HOME", "c:\Program Files\Java\jre$JRE_PATH", "Machine")
[System.Environment]::SetEnvironmentVariable("PATH", $Env:Path + ";c:\Program Files\Java\jre$JRE_PATH\bin", "Machine")
Write-Host 'Done. Goodbye.'