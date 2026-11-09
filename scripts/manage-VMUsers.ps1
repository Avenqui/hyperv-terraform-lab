
param(
    [Parameter(Mandatory)]
    [ValidateSet("Create", "Remove", "List", "Check")]
    [string]$Action,

    [string]$Username,

    [string]$VMName = "All"
)

$LogPath = "C:\Hyper-V\Terraform-Lab\logs\vm-users.log"

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

# Funktion 2: Hitta VM:ar
function Get-TargetVMs {
    param([string]$Name)

    $VMs = @(Get-VM -Name "SRV-TEST*" -ErrorAction Stop)

    if ($Name -ne "All") {
        $VMs = @($VMs | Where-Object {
            $_.Name -eq $Name
        })
    }

    return $VMs
}

# Funktion 3: Hantera användare
function Manage-LocalUser {
    param(
        [string]$TargetVM,
        [string]$Operation,
        [string]$User,
        [pscredential]$Credential,
        [securestring]$Password
    )

    Invoke-Command -VMName $TargetVM `
        -Credential $Credential `
        -ErrorAction Stop `
        -ArgumentList $Operation, $User, $Password `
        -ScriptBlock {

            param($Operation, $User, $Password)

            switch ($Operation) {

                "Create" {
                    $Existing = Get-LocalUser -Name $User `
                        -ErrorAction SilentlyContinue

                    if ($Existing) {
                        return "Användaren $User finns redan."
                    }

                    New-LocalUser -Name $User `
                        -Password $Password `
                        -ErrorAction Stop | Out-Null

                    return "Användaren $User skapades."
                }

                "Remove" {
                    $Existing = Get-LocalUser -Name $User `
                        -ErrorAction SilentlyContinue

                    if (-not $Existing) {
                        return "Användaren $User finns inte."
                    }

                    Remove-LocalUser -Name $User `
                        -ErrorAction Stop

                    return "Användaren $User togs bort."
                }

                "Check" {
                    $Existing = Get-LocalUser -Name $User `
                        -ErrorAction SilentlyContinue

                    if ($Existing) {
                        return "Användaren $User finns."
                    }

                    return "Användaren $User finns inte."
                }

                "List" {
                    Get-LocalUser | ForEach-Object {
                        "$($_.Name) - Enabled: $($_.Enabled)"
                    }
                }
            }
        }
}

# Skapa loggmapp
$LogDirectory = Split-Path $LogPath -Parent

if (-not (Test-Path $LogDirectory)) {
    New-Item -ItemType Directory -Path $LogDirectory `
        -Force | Out-Null
}

# Kontrollera parametrar
if ($Action -ne "List" -and
    [string]::IsNullOrWhiteSpace($Username)) {
    throw "Username måste anges för $Action."
}

# Hämta VM:ar
try {
    $VMs = @(Get-TargetVMs -Name $VMName)
}
catch {
    Write-Log "Kunde inte hämta VM:ar: $($_.Exception.Message)" "ERROR"
    throw
}

if ($VMs.Count -eq 0) {
    Write-Log "Inga matchande VM:ar hittades." "WARNING"
    return
}

# Fråga efter administratörsuppgifter
$Credential = Get-Credential -Message "Ange administratörskonto för VM:arna"

# Fråga efter lösenord vid Create
$Password = $null

if ($Action -eq "Create") {
    $Password = Read-Host `
        "Ange lösenord för $Username" `
        -AsSecureString
}

Write-Log "Startar användarhantering. Action: $Action"

foreach ($VM in $VMs) {

    if ($VM.State -ne "Running") {
        Write-Log "$($VM.Name) är inte igång." "WARNING"
        continue
    }

    try {
        Write-Log "Bearbetar $($VM.Name)"

        $Result = Manage-LocalUser `
            -TargetVM $VM.Name `
            -Operation $Action `
            -User $Username `
            -Credential $Credential `
            -Password $Password

        foreach ($Line in $Result) {
            Write-Log "$($VM.Name): $Line"
        }
    }
    catch {
        Write-Log "$($VM.Name): $($_.Exception.Message)" "ERROR"
    }
}

Write-Log "Användarhantering avslutad."
