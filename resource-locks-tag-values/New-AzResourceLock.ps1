$resourceGroups = Get-AzResourceGroup # Gets all RG's. Alternatively, create an array of target RG's.
$lockTagValue = "Production"
$applyResourceLock = $true

# Loop through each Resource Group in the subscription
foreach ($resourceGroup in $resourceGroups) {

    # Check if any Resource Group has tags with a value containing $lockTagValue
    $tagExists = Get-AzResourceGroup -Name $resourceGroup.ResourceGroupName | Where-Object { $_.Tags.Values -contains $lockTagValue }

    if (!$tagExists) {
        Write-Output "No tags found for '$($resourceGroup.ResourceGroupName)' that match '$($lockTagValue)'. Continuing to next (if any..)"
        Continue
    }

    # Set $resourceGroupName
    $resourceGroupName = $tagExists.ResourceGroupName
   
    Write-Output "$($resourceGroupName) has a '$($lockTagValue)' tag applied. Checking to see if Resource Group already has a lock applied."

    # Check if Resource Group already has a lock
    $lockExists = Get-AzResourceLock -ResourceGroupName $resourceGroupName -AtScope

    if (!$lockExists) {
        Write-Output "$resourceGroupName does not have a lock."
        # Only apply Resource Lock if the $applyResourceLock variable is set to $true
        if ($applyResourceLock -eq $true) {
            Write-Output "Adding Resource Lock to Resource Group: $($resourceGroupName)"
            New-AzResourceLock -LockLevel CanNotDelete -LockNotes "Prevents accidental deletion of resource groups" -LockName "ResourceLock" -ResourceGroupName $resourceGroupName -force   
        }
        else {
            Write-Output "Apply resource locks is set to false. No resource locks will be added."            
        }
    }
    else {
        Write-Output "$resourceGroupName already has a Resource Lock applied."
    }
}