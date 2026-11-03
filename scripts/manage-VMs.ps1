param(
    [Parameter(Mandatory)]
    [ValidateSet("Start", "Stop", "Status")]
    [string]$Action
)

$LogPath = "C:\Hyper-V\Terraform-lab\logs\vm-management.log"

function Write-Log {
    param(
        [string]$Message,
        [string]$Level = "INFO"
    )

    $Timestamp = Get-Date -Format "yyyy-mm-dd HH:mm:ss"
    $LogMessage = "[$Timestamp] [$Level] $Message"
    Write-Host $LogMessage
    Add-Content -Path $LogPath -Value $LogMessage
}

$VMs = @(Get-VM -ErrorAction Stop | Where-Object {
    $_.Name -like "SRV-TEST*"
})

if ($VMs.Count -eq 0) {
    Write-Log "No WMs found." "Warning"
    return
}

Write-Log "------------------Start VM management. Action $Action ------------------"

foreach ($VM in $VMs) {
    try {
        switch ($Action) {
            "Start" {
                if ($VM.State -eq "Running"){
                    Write-log "$($VM.Name) already running"
                    Continue
                }
                Write-Log "Starting $($VM.Name)"
                Start-VM -Name $VM.Name -ErrorAction Stop | Out-Null
                Write-Log "$($VM.Name) is now up and running"
            
            }
            "Stop" {
                if ($VM.State -eq "Off") {
                    Write-Log "$($VM.Name) is already turned off"
                    Continue
                }
                
                Write-Log "Shutting down $($VM.Name)"
                Stop-VM -Name $VM.Name -ErrorAction Stop | Out-Null
                Write-Log "$($VM.Name) is now shutdown"
            }

            "Status" {
                $CurrentVM = Get-VM -Name $VM.Name
                Write-Log "$($CurrentVM.Name) - State $($CurrentVM.State)"
            }
        }
    }
    catch {
        Write-Log "$($VM.Name): $($_.Exception.Message)" "ERROR, JIPPI!"
    }
}

Write-Log "------------------VM management ended------------------"
