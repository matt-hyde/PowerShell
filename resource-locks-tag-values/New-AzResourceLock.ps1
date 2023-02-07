$resourceGroups = Get-AzResourceGroup
$searchTagValues = @("Production", "Prd", "Prod")
$applyResourceLock = $true

foreach ($resourceGroup in $resourceGroups) {
    foreach ($tagValue in $searchTagValues) {
        $tags = (Get-AzResourceGroup $resourceGroup.ResourceGroupName).Tags.Values

        if ($tags -notcontains $tagValue) {
            Write-Output "No '$tagValue' tag found in $($resourceGroup.ResourceGroupName), moving to the next"
            continue
        }
        $locks = Get-AzResourceLock -ResourceGroupName $resourceGroup.ResourceGroupName -AtScope
        if (!$locks) {
            Write-Output "$($resourceGroup.ResourceGroupName) does not have a lock."
            if ($applyResourceLock) {
                Write-Output "Adding Resource Lock to Resource Group: $($resourceGroup.ResourceGroupName)"
                New-AzResourceLock -LockLevel CanNotDelete -LockNotes "Prevents accidental deletion of resource groups" -LockName "ResourceLock" -ResourceGroupName $resourceGroup.ResourceGroupName -force
            }
            else {
                Write-Output "Apply resource locks is set to false. No resource locks will be added." 
            }
        }
        else {
            Write-Output "$($resourceGroup.ResourceGroupName) already has a Resource Lock applied."
        }
    }
}
