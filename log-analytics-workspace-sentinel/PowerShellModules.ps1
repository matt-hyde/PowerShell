function InstallModules([array]$ModuleNames) {
    foreach ($module in $ModuleNames) {
        $installedModule = Get-Module -ListAvailable -Name $module;
        if ($null -eq $installedModule) {
            Write-Output "The PowerShell module: $module was not found. Installing."
            Install-Module $module -Scope CurrentUser -Force -AllowClobber; # Install from gallery
            Import-Module -Name $module -Force; # Import into current session   
        }
        else {
            Write-Output "PowerShell module: $module has already been installed."
            Import-Module -Name $module -Force; # Import into current session
        } 
    }     
}

function RemoveModules([array]$ModuleNames) {
    foreach ($module in $ModuleNames) {
        $installedModule = Get-Module -ListAvailable -Name $module;
        if ($null -eq $installedModule) {
            Write-Output "PowerShell Module: $module was not found. No work to be done here"            
        }
        else {
            Write-Output "PowerShell module: $module will be removed."
            Remove-Module -Name $module -Force -ErrorAction SilentlyContinue;
        } 
    }     
}