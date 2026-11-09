
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
                        return "The user $User already exists"
                    }

                    New-LocalUser -Name $User `
                        -Password $Password `
                        -ErrorAction Stop | Out-Null

                    return "Created user $User."
                }

                "Remove" {
                    $Existing = Get-LocalUser -Name $User `
                        -ErrorAction SilentlyContinue

                    if (-not $Existing) {
                        return "The user $User does not exist"
                    }

                    Remove-LocalUser -Name $User `
                        -ErrorAction Stop

                    return "The user $User is removed."
                }

                "Check" {
                    $Existing = Get-LocalUser -Name $User `
                        -ErrorAction SilentlyContinue

                    if ($Existing) {
                        return "The user $User does exist."
                    }

                    return "The user $User does not exist."
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
    throw "Provide an username for $Action."
}

# Hämta VM:ar
try {
    $VMs = @(Get-TargetVMs -Name $VMName)
}
catch {
    Write-Log "Could not aquire virtual machines: $($_.Exception.Message)" "ERROR"
    throw
}

if ($VMs.Count -eq 0) {
    Write-Log "No virtual machines with that name found" "WARNING"
    return
}

# Fråga efter administratörsuppgifter
$Credential = Get-Credential -Message "Enter admin account for virtual machines"

# Fråga efter lösenord vid Create
$Password = $null

if ($Action -eq "Create") {
    $Password = Read-Host `
        "Enter password for user $Username" `
        -AsSecureString
}

Write-Log "Starting user configuration. Action: $Action"

foreach ($VM in $VMs) {

    if ($VM.State -ne "Running") {
        Write-Log "$($VM.Name) is not running." "WARNING"
        continue
    }

    try {
        Write-Log "Configurating $($VM.Name)"

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

Write-Log "User configuration ended."
