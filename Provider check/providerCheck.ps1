$schema = Get-Content "$PSScriptRoot\provider-schema.json" -Raw | ConvertFrom-Json
$vm = $schema.provider_schemas.'registry.terraform.io/windsorcli/hyperv'.resource_schemas.hyperv_vm

# $vm.block.attributes.PSObject.Properties | ForEach-Object {
#     [PSCustomObject]@{
#         Name = $_.Name
#         Required = $_.Value.required
#         Optional = $_.Value.optional
#         Computed = $_.Value.computed
#     }
# } | Format-Table -AutoSize

#$vm.block.attributes.cpu | ConvertTo-Json -Depth 15

#$vm.block.attributes.memory | ConvertTo-Json -Depth 15

#$vm.block.attributes.hard_disk_drive | ConvertTo-Json -Depth 15

# $image = $schema.provider_schemas.'registry.terraform.io/windsorcli/hyperv'.resource_schemas.hyperv_image_file

# $image.block.attributes.PSObject.Properties | ForEach-Object {
#     [PSCustomObject]@{
#         Name = $_.Name
#         Required = $_.Value.required
#         Optional = $_.Value.optional
#         Computed = $_.Value.computed
#         Description = $_.Value.description
#     }
# } | Format-Table -Wrap

# $vm.block.attributes.hard_disk_drive.nested_type.attributes.PSObject.Properties | ForEach-Object {
#     [PSCustomObject]@{
#        Name = $_.Name
#        Required = $_.Value.required
#        Optional = $_.Value.optional
#     }
# } | Format-Table -AutoSize

$vm.block.attributes.network_adapter.nested_type.attributes.PSObject.Properties| ForEach-Object {
    [PSCustomObject]@{
       Name = $_.Name
       Required = $_.Value.required
       Optional = $_.Value.optional
    }
} | Format-Table -AutoSize