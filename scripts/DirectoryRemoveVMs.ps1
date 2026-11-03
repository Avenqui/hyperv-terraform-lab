Get-ChildItem "C:\Hyper-V\VMs" -Directory |
    Where-Object {
        @(Get-ChildItem $_.FullName -Force).count -eq 0
    } |
    Remove-Item -Force