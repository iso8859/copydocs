# Check https://github.com/iso8859/copydocs for the instructions
# Get the destination folder from the command line arguments
if ($args.Count -eq 0) {
    throw "Please provide the destination folder as a command line argument."
}
# Create the destination folder if it does not exist
if (-not (Test-Path -Path $args[0])) {
    New-Item -ItemType Directory -Path $args[0] | Out-Null
}

# if there is two argement the second one is the temp folder
$TempFolder = $env:TEMP
if ($args.Count -eq 2) {
    $TempFolder = $args[1]
    if (-not (Test-Path -Path $TempFolder)) {
        New-Item -ItemType Directory -Path $TempFolder | Out-Null
    }
}   

# Parse the rclone downloads page to get the latest windows-amd64.zip link
$url = 'https://rclone.org/downloads/'
$page = Invoke-WebRequest -Uri $url -UseBasicParsing
$regex = 'href\s*=\s*"([^"]*windows-amd64\.zip)"'
$matches = [regex]::Matches($page.Content, $regex)
if ($matches.Count -eq 0) {
    throw "Could not find a windows-amd64.zip link on the rclone downloads page."
}
$RCloneSrc = $matches[0].Groups[1].Value
if ($RCloneSrc -notmatch '^https?://') {
    $RCloneSrc = "https://rclone.org/$RCloneSrc" -replace '/+', '/'
    $RCloneSrc = $RCloneSrc -replace 'https:/', 'https://'
}
$RCloneFileName = [System.IO.Path]::GetFileNameWithoutExtension([System.IO.Path]::GetFileName($RCloneSrc))
$RCloneDst = "$TempFolder\$RCloneFileName.zip"
$ExpandFolder = "$TempFolder\$RCloneFileName"

Write-Output "Downloading $RCloneSrc ..."
Invoke-WebRequest -Uri $RCloneSrc -UseBasicParsing -OutFile $RCloneDst
Expand-Archive -Path $RCloneDst -DestinationPath $ExpandFolder -Force
Remove-Item -Path $RCloneDst -Force -ErrorAction SilentlyContinue
# search for rclone.exe in the extracted folder
$RClonePath = (Get-ChildItem -Path $ExpandFolder -Recurse -Filter "rclone.exe" | Select-Object -First 1).FullName

$dests = @("Desktop", "Favorites", "Downloads")
foreach ($dest in $dests) {
    $s = "shell:" + $dest
    $src = (New-Object -ComObject Shell.Application).Namespace($s).Self.Path
    $targetPath = Join-Path $args[0] $dest
    Write-Output "Syncing $src to $dest"
    & $RClonePath sync -P $src $targetPath
}
$dests = @("MyDocuments", "MyPictures", "MyMusic", "MyVideos")
foreach ($dest in $dests) {
    $src = [System.Environment]::GetFolderPath($dest)
    $targetPath = Join-Path $args[0] $dest
    Write-Output "Syncing $src to $dest"
    & $RClonePath sync -P $src $targetPath
}
#delete rclone folder
Remove-Item -Path (Split-Path $ExpandFolder) -Recurse -Force -ErrorAction SilentlyContinue