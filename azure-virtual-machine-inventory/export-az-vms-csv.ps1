# Define file locations
$curDir = Get-Location; # This will save the files in the folder from where you run the script. Change if required.
$csvName = "azureinventory.csv";
$csvPath = [System.IO.Path]::Combine($curDir, $csvName);
$xlsxPath = $csvPath -replace ".csv", ".xlsx";

# Install ImportExcel module
$importExcelModule = Get-Module -Name ImportExcel -ListAvailable | Measure-Object;
if ($importExcelModule.Count -eq 0) {
    Write-Output "Module 'ImportExcel' is not installed. Installing now..."
    Install-Module ImportExcel -Scope CurrentUser -Force;
}
else {
    Write-Output "Module 'ImportExcel' is installed."
}

# Get All VM's within a subscription that you have access to, then create a custom PS object and map values.
$VMs = Get-AzVM
$vmOutput = $VMs | ForEach-Object {
    [PSCustomObject]@{
        "VM Name"           = $_.Name
        "Resource Group"    = $_.ResourceGroupName
        "VM Type"           = $_.StorageProfile.osDisk.osType
        "VM Offer"          = $_.StorageProfile.ImageReference.Offer
        "VM Publisher"      = $_.StorageProfile.ImageReference.Publisher
        "VM Sizes"          = $_.HardwareProfile.VmSize
        "VM OS Disk Size"   = $_.StorageProfile.OsDisk.DiskSizeGB
        "VM OS Disk Type"   = $_.StorageProfile.OsDisk.ManagedDisk.StorageAccountType
        "VM Data Disk Size" = ($_.StorageProfile.DataDisks.DiskSizeGB) -join ','
        "VM Data Disk Type" = $_.StorageProfile.DataDisks.ManagedDisk.StorageAccountType 
    }
}
# Export to CSV format
$vmOutput | export-csv $csvPath -delimiter "," -force -notypeinformation

# Check csv exists before going any further.
if (-not(Test-Path -Path $csvPath -PathType Leaf)) {
    throw "csv file doesn't exist. Please ensure it is in the correct folder."
}
else {
    Write-Output "csv: '$csvName' has been found"
}

try {
    # Convert the .csv file to .xlsx using the ImportExcel module.
    Write-Output "Converting $csvName to .xlsx"
    Import-Csv $csvPath | Export-Excel $xlsxPath
}
catch {
    throw $_.Exception.Message
}