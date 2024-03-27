$ParentPath = Split-Path -Path $PSScriptRoot -Parent

$gitHooksPath = "$ParentPath\.git\hooks"
$repoHooksDir = "$ParentPath\.github\hooks"

if (-not (Test-Path -Path $gitHooksPath)) {
    Write-Host "The path to .git/hooks does not exist."
    exit
}

$hookFiles = Get-ChildItem -Path $repoHooksDir -File | Where-Object { $_.Extension -eq '' }

foreach ($file in $hookFiles) {
    $destination = Join-Path -Path $gitHooksPath -ChildPath $file.Name
    Copy-Item -Path $file.FullName -Destination $destination -Force
    Write-Host "Copied $($file.Name) to $gitHooksPath"
}

Write-Host "Hooks setup complete."
