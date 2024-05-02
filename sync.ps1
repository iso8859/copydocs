# Check https://github.com/iso8859/copydocs for the instructions

# Enable TLSv1.2 for compatibility with older clients
[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

$RCloneVersion = "v1.66.0"
$RCloneFileName = "rclone-$RCloneVersion-windows-amd64"
$RCloneSrc = "https://downloads.rclone.org/$RCloneVersion/$RCloneFileName.zip"
$RCloneDst = "$env:TEMP\$RCloneFileName.zip"

$response = Invoke-WebRequest -Uri $RCloneSrc -UseBasicParsing -OutFile $RCloneDst
# unzip
Expand-Archive -Path $RCloneDst -DestinationPath $env:TEMP -Force
# in args we have the destination path
$RClonePath = Join-Path "$env:TEMP" "$RCloneFileName" "rclone.exe"
#$RClonePath = "C:\Users\rth\source\repos\WindowsFormsApp1\WindowsFormsApp1\bin\Debug\WindowsFormsApp1.exe"
$dests = @("Desktop", "Favorites", "Downloads")
foreach ($dest in $dests) {
    $s = "shell:" + $dest
    $src = (New-Object -ComObject Shell.Application).Namespace($s).Self.Path
    Write-Output "Syncing $src to $dest"
    & $RClonePath sync -P $src $args\$dest
}
$dests = @("MyDocuments", "MyPictures", "MyMusic", "MyVideos")
foreach ($dest in $dests) {
    $src = [System.Environment]::GetFolderPath($dest)
    Write-Output "Syncing $src to $dest"
    & $RClonePath sync -P $src $args\$dest
}