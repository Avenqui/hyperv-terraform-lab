param(
    [Parameter(Mandatory = $true)]
    [string]$VhdPath,

    [Parameter(Mandatory = $true)]
    [string]$UnattendPath
)

$LogDirectory = Join-Path $PSScriptRoot "..\logs"
$LogFile = Join-Path $LogDirectory "deployment.log"

if (-not (Test-Path $LogDirectory)) {
    New-Item -Itemtype Directory -Path $LogDirectory -Force | Out-Null
}

Function Write-Log {
    param(
        [string]$Message
    )
$Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$LogMessage = "$Timestamp - $Message"
Write-Host $LogMessage
Add-Content -Path $LogFile -Value $LogMessage
}

$ErrorActionPreference = "Stop"

if (-not (Test-Path $VhdPath)) {
    throw "VHDX-file does not exist: $VhdPath"
}

if (-not (Test-Path $UnattendPath)) {
    throw "Unattend-file does not exist: $UnattendPath"
}

$mounted = $false

try {
    Write-Log "Mounting $VhdPath"

    $disk = Mount-VHD -Path $VhdPath -Passthru | Get-Disk
    $mounted = $true

    # Hitta Windows-partitionen
    $partition = Get-Partition -DiskNumber $disk.Number |
        Where-Object {
            $_.Type -eq "Basic" -and $_.Size -gt 10GB
        } |
        Sort-Object Size -Descending |
        Select-Object -First 1

    if (-not $partition) {
        throw "Windows partition not found."
    }

    # Kontrollera om partitionen redan har en enhetsbokstav
    if ($partition.DriveLetter) {

        $driveLetter = $partition.DriveLetter

        Write-Log "Existing drive letter: ${driveLetter}:"

    }
    else {

        # Hitta en ledig enhetsbokstav
        $usedLetters = @(
            Get-Volume |
            Where-Object DriveLetter |
            ForEach-Object { [string]$_.DriveLetter }
        )

        $driveLetter = @('Z','Y','X','W','V','U','T','S','R','Q') |
            Where-Object { $_ -notin $usedLetters } |
            Select-Object -First 1

        if (-not $driveLetter) {
            throw "No available drive letter."
        }

        Add-PartitionAccessPath `
            -DiskNumber $disk.Number `
            -PartitionNumber $partition.PartitionNumber `
            -AccessPath "${driveLetter}:\" `
            -ErrorAction Stop
    }

    # Kontrollera Windows-installationen
    $windowsPath = "${driveLetter}:\Windows"

    if (-not (Test-Path "$windowsPath\System32")) {
        throw "The partition does not have a Windows installation."
    }

    # Skapa Panther-mappen
    $pantherPath = "$windowsPath\Panther"

    New-Item `
        -ItemType Directory `
        -Path $pantherPath `
        -Force | Out-Null

    # Kopiera Unattend.xml
    $destination = "$pantherPath\Unattend.xml"

    Copy-Item `
        -Path $UnattendPath `
        -Destination $destination `
        -Force

    Write-Log "Unattend.xml copied to $destination"
}
finally {

    if ($mounted) {
        Dismount-VHD -Path $VhdPath
        Write-Log "Drive unmounted."
    }
}