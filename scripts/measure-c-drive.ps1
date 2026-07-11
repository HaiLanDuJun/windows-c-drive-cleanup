$ErrorActionPreference = "SilentlyContinue"

function Get-DirectorySizeBytes {
    param([Parameter(Mandatory = $true)][string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) { return $null }
    $sum = (Get-ChildItem -LiteralPath $Path -Force -Recurse -File -ErrorAction SilentlyContinue |
        Measure-Object -Property Length -Sum).Sum
    if ($null -eq $sum) { return 0 }
    return [int64]$sum
}

$drive = Get-PSDrive C
[PSCustomObject]@{
    Kind = 'Drive'
    Path = 'C:'
    GB = [math]::Round($drive.Used / 1GB, 2)
    FreeGB = [math]::Round($drive.Free / 1GB, 2)
    Risk = 'Info'
}

$paths = @(
    @{Path="$env:LOCALAPPDATA\Temp"; Risk='Low'},
    @{Path='C:\Windows\Temp'; Risk='Low'},
    @{Path='C:\Windows\SoftwareDistribution\Download'; Risk='Low'},
    @{Path='C:\$Recycle.Bin'; Risk='Low'},
    @{Path="$env:USERPROFILE\Downloads"; Risk='High'},
    @{Path="$env:APPDATA\npm-cache"; Risk='Low'},
    @{Path="$env:LOCALAPPDATA\npm-cache"; Risk='Low'},
    @{Path="$env:USERPROFILE\.npm"; Risk='Low'},
    @{Path="$env:USERPROFILE\.m2\repository"; Risk='Medium'},
    @{Path="$env:USERPROFILE\.gradle\caches"; Risk='Medium'},
    @{Path="$env:USERPROFILE\.cache"; Risk='Medium'},
    @{Path="$env:LOCALAPPDATA\CrashDumps"; Risk='Low'},
    @{Path='C:\ProgramData\Microsoft\Windows\WER'; Risk='Low'},
    @{Path='C:\ProgramData\Package Cache'; Risk='Medium'},
    @{Path="$env:USERPROFILE\.ollama"; Risk='High'},
    @{Path="$env:USERPROFILE\.lmstudio"; Risk='High'},
    @{Path="$env:LOCALAPPDATA\Docker"; Risk='High'},
    @{Path="$env:USERPROFILE\.docker"; Risk='Medium'},
    @{Path="$env:LOCALAPPDATA\JetBrains"; Risk='Medium'},
    @{Path="$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Cache"; Risk='Low'},
    @{Path="$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Cache"; Risk='Low'}
)

$results = foreach ($item in $paths) {
    $bytes = Get-DirectorySizeBytes -Path $item.Path
    if ($null -ne $bytes) {
        [PSCustomObject]@{
            Kind = 'Candidate'
            Path = $item.Path
            GB = [math]::Round($bytes / 1GB, 2)
            FreeGB = $null
            Risk = $item.Risk
        }
    }
}

$results | Sort-Object GB -Descending