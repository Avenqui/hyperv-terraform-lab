
$LogPath = "C:\Hyper-V\Terraform-Lab\logs\vm-configuration.log"

# Funktion 1: Loggning
function Write-Log {
    param(
        [string]$Message,
        [string]$Level = "INFO"
    )

    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $LogMessage = "[$Timestamp] [$Level] $Message"

    Write-Host $LogMessage
    Add-Content -Path $LogPath -Value $LogMessage
}

# Funktion 2: Hämta alla körande VM:ar
function Get-TargetVMs {
    Get-VM -Name "SRV-TEST*" |
        Where-Object { $_.State -eq "Running" }
}

# Funktion 3: Konfigurera inloggning
function Set-VMLogin {
    param(
        [string]$VMName,
        [pscredential]$Credential
    )

    Invoke-Command -VMName $VMName `
        -Credential $Credential `
        -ErrorAction Stop `
        -ScriptBlock {

            $Path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"

            Set-ItemProperty `
                -Path $Path `
                -Name "dontdisplaylastusername" `
                -Value 1 `
                -ErrorAction Stop

            Get-ItemPropertyValue `
                -Path $Path `
                -Name "dontdisplaylastusername"
        }
}

# Skapa loggmapp
$LogDirectory = Split-Path $LogPath -Parent

if (-not (Test-Path $LogDirectory)) {
    New-Item -ItemType Directory -Path $LogDirectory -Force | Out-Null
}

# Hämta VM:ar
$VMs = @(Get-TargetVMs)

if ($VMs.Count -eq 0) {
    Write-Log "No Running Virtual machines were found." "WARNING"
    return
}

# Administratörsuppgifter för gästerna
$Credential = Get-Credential

foreach ($VM in $VMs) {
    try {
        Write-Log "Configue login screen on $($VM.Name)"

        $Result = Set-VMLogin `
            -VMName $VM.Name `
            -Credential $Credential

        if ($Result -eq 1) {
            Write-Log "$($VM.Name): Setting is activated."
        }
        else {
            Write-Log "$($VM.Name): Unexpected value: $Result" "WARNING"
        }
    }
    catch {
        Write-Log "$($VM.Name): $($_.Exception.Message)" "ERROR"
    }
}

Write-Log "Configuration ended."
