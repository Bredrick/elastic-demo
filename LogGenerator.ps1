param (
    [string]$source = "App"
 )

$levels = @("error", "warning", "info")
$file = "C:\app\logs\log-$source.txt"



while ($true) {
    $level = Get-Random -Maximum 3
    $message = -join ((65..90) + (97..122) | Get-Random -Count 50 | % {[char]$_})
    $time = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $output = $time + " " + $levels[$level] + " " + $source + " " + $message + "`n"
    echo $output | out-file $file -append -encoding utf8
    $sleepTime = Get-Random -Maximum 3000
    Start-Sleep -Milliseconds $sleepTime
}