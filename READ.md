# Hyper-V Terraform Lab¨

## Github-link

www.github.com/Avenqui/hyperv-terraform-lab

## Create VMs

Using Terraform, we create VMs in Hyper-V. We use differencing disks to make VM deployment faster.

This requires a parent disk containing a configured `Unattend.xml` file.

To update the configuration, number of VMs, or VM names, edit the `variables.tf` file.

---

## Manage Users

Using `Terraform-Lab/scripts/Manage-VMUsers.ps1`, we can list, create, remove, and check local users.

Below are the required parameters.

### List Users

```powershell
-Action List
```
Displays all local users on all VMs.

```powershell
-Action List -VMName "VM_Name"
```
Displays all local users on the specified VM.

### Create Users

```powershell
-Action Create -Username "Username" -VMName "VM_Name"
```
Creates a local user only on the specified VM.

```powershell
-Action Create -Username "Username"
```
Creates the local user on all VMs.

### Remove Users

```powershell
-Action Remove -Username "Username" -VMName "VM_Name"
```
Removes the local user only from the specified VM.

```powershell
-Action Remove -Username "Username"
```
Removes the local user from all VMs.

### Check Users

```powershell
-Action Check -Username "Username"
```
Checks whether the user exists on all VMs.

```powershell
-Action Check -Username "Username" -VMName "VM_Name"
```
Checks whether the user exists on the specified VM.

---

## Manage VMs

Script: `Manage-VMs.ps1`

### Check VM Status

```powershell
-Action Status
```
Checks the status of all VMs.

### Stop VMs

```powershell
-Action Stop
```
Stops all VMs.

### Start VMs

```powershell
-Action Start
```
Starts all VMs.

### Manage a Specific VM

```powershell
-Action "Action" -VMName "VM_Name"
```
Runs the specified action only on the selected VM.

---

## Activate Local User Login

Script: `Configure-VMLogin.ps1`

Due to an issue in Hyper-V, you sometimes cannot log in as a local user through the GUI, even if the user account exists.

This script changes the login settings so that you must manually enter the username when logging in.

This makes it possible to log in with other local accounts besides Administrator.

---

## Remove Empty VM Directories

Script: `Directory-Remove-VMs.ps1`

When using `terraform destroy`, everything is removed except the directories that were created when the VMs were initially deployed.

This script automatically removes empty directories from the specified path.

---

## Terraform Auto Log

Script: `TerraformAutoLog`

Permanently enables Terraform logging for the current Windows user account.

This allows Terraform actions to be logged automatically.