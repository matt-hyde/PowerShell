<#
.SYNOPSIS
Creates a LAW and enables Sentinel (SecurityInsights)

.PARAMETER -ResourceGroupName
Name of the Resource Group where the Log Analytics Workspace will be deployed.

.PARAMETER -WorkspaceName
Log Analytics Workspace Name.

#>

param (
    [Parameter(Mandatory = $true)]
    [string] $ResourceGroupName,

    [Parameter(Mandatory = $true)]
    [string] $WorkspaceName
)

$workspaceSku = "pergb2018"

# Set required modules.
$requiredModules = ("Az.SecurityInsights", "Az.MonitoringSolutions")

# Call function
. ".\PowerShellModules.ps1"

# Install required modules.
InstallModules($requiredModules)

# Get Resource Group
$ResourceGroup = Get-AzResourceGroup -Name $ResourceGroupName -ErrorAction SilentlyContinue
if ($null -eq $ResourceGroup) {
    throw "Please ensure Resource Group: '$ResourceGroupName' exists before continuing."
}

# Check if LAW already exists.
$LogAnalyticsWorkspace = Get-AzOperationalInsightsWorkspace -Name $WorkspaceName -ResourceGroupName $ResourceGroupName -ErrorAction SilentlyContinue
# Create LAW if it does not exist.
if ($null -eq $LogAnalyticsWorkspace) {
    Write-Output "Creating Log Analytics Workspace: '$WorkspaceName'"
    New-AzOperationalInsightsWorkspace -Location $ResourceGroup.Location -Name $WorkspaceName -Sku $workspaceSku -ResourceGroupName $ResourceGroupName
    $LogAnalyticsWorkspace = Get-AzOperationalInsightsWorkspace -Name $WorkspaceName -ResourceGroupName $ResourceGroupName -ErrorAction SilentlyContinue
}
else {
    Write-Output "Log Analytics Workspace: '$WorkspaceName' already exists. Skipping..."
}

# Get all solutions in Resource Group where name matches "SecurityInsights" and $WorkplaceName
$solutions = Get-AzMonitorLogAnalyticsSolution -ResourceGroupName $ResourceGroupName | `
    Where-Object { $_.Name -match "SecurityInsights" -and $_.Name -match $WorkspaceName }

# Create solution if it doesn't exist.
if ($null -eq $solutions) {
    New-AzMonitorLogAnalyticsSolution -Type SecurityInsights `
        -ResourceGroupName $ResourceGroupName `
        -Location $ResourceGroup.Location `
        -WorkspaceResourceId $LogAnalyticsWorkspace.ResourceId    
}
else {
    Write-Host "Azure Sentinel is already installed on workspace '$($WorkspaceName)'"
}