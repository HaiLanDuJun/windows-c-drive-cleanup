param(
    [switch]$Execute,
    [switch]$SkipTemp,
    [switch]$SkipNpmCache,
    [switch]$SkipWindowsUpdateDownload
)

$ErrorActionPreference = "SilentlyContinue"

function Get-DirectorySizeBytes {
    param([Parameter(Mandatory = $true)][string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) { return 0 }
    $sum = (Get-ChildItem -LiteralPath $Path -Force -Recurse -File -ErrorAction SilentlyContinue |
        Measure-Object -Property Length -Sum).Sum
    if ($null -eq $sum) { return 0 }
    return [int64]$sum
}

function Clear-DirectoryChildren {
    param([Parameter(Mandatory = $true)][string]$Path)
    $resolved = (Resolve-Path -LiteralPath $Path -ErrorAction SilentlyContinue).Path
    if (-not $resolved) { return }
    Get-ChildItem -LiteralPath $resolved -Force -ErrorAction SilentlyContinue |
        Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
}

$before = Get-PSDrive C
[PSCustomObject]@{Action='Before'; Path='C:'; GB=$null; FreeGB=[math]::Round($before.Free / 1GB, 2); Note='No deletion yet'}

$targets = New-Object System.Collections.Generic.List[string]
if (-not $SkipTemp) {
    $targets.Add("$env:LOCALAPPDATA\Temp")
    $targets.Add('C:\Windows\Temp')
}
if (-not $SkipWindowsUpdateDownload) {
    $targets.Add('C:\Windows\SoftwareDistribution\Download')
}

foreach ($target in $targets) {
    if (Test-Path -LiteralPath $target) {
        $gb = [math]::Round((Get-DirectorySizeBytes -Path $target) / 1GB, 2)
        [PSCustomObject]@{Action= if ($Execute) {'Clean'} else {'DryRun'}; Path=$target; GB=$gb; FreeGB=$null; Note='Directory children only'}
        if ($Execute) { Clear-DirectoryChildren -Path $target }
    }
}

$npmCache = if (Test-Path -LiteralPath "$env:LOCALAPPDATA\npm-cache") { "$env:LOCALAPPDATA\npm-cache" } else { "$env:APPDATA\npm-cache" }
if (-not $SkipNpmCache -and (Test-Path -LiteralPath $npmCache)) {
    $gb = [math]::Round((Get-DirectorySizeBytes -Path $npmCache) / 1GB, 2)
    [PSCustomObject]@{Action= if ($Execute) {'CleanNpmCache'} else {'DryRunNpmCache'}; Path=$npmCache; GB=$gb; FreeGB=$null; Note='Uses npm cache clean when npm exists'}
    if ($Execute) {
        $npm = Get-Command npm -ErrorAction SilentlyContinue
        if ($npm) {
            npm cache clean --force | Out-Null
        } else {
            Clear-DirectoryChildren -Path $npmCache
        }
    }
}

$after = Get-PSDrive C
[PSCustomObject]@{Action='After'; Path='C:'; GB=$null; FreeGB=[math]::Round($after.Free / 1GB, 2); Note= if ($Execute) {'Cleanup executed'} else {'Dry run only; re-run with -Execute after approval'}}