$schema = Get-Content "$PSScriptRoot\provider-schema.json" -Raw | ConvertFrom-Json

$vm = $schema.provider_schemas.'registry.terraform.io/windsorcli/hyperv'.resource_schemas.hyperv_vm

$vm.block.attributes.PSObject.Properties | ForEach-Object {
    [PSCustomObject]@{
        Name = $_.Name
        Required = $_.Value.required
        Optional = $_.Value.optional
        Computed = $_.Value.computed
    }
} | Format-Table -AutoSize