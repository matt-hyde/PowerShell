<#
.SYNOPSIS

AllowHostedAgentIP - Function which gets the IP address of the Azure DevOps Hosted agent, and adds it to a Network Security Group.

RemoveHostedAgentIP - Function which removes the Azure DevOps Hosted agent IP from the Network Security Group.

This script was designed to be called via a pipeline. Allow the DevOps agents to communicate with resources behind a NSG and then remove the IP afterwards to ensure it remains secure.

#>

param (
    [Parameter(Mandatory = $true)]
    [string] $ResourceGroupName,

    [Parameter(Mandatory = $true)]
    [string] $NetworkSecurityGroupName,
    
    [Parameter(Mandatory = $true)]
    [string] $RuleName,

    [Parameter(Mandatory = $true)]
    [string] $Priority
)

# Get Release Agent IP
$agentIP = (New-Object net.webclient).downloadstring("http://checkip.dyndns.com") -replace "[^\d\.]"

# Get Network Security Group
$networkSecurityGroup = Get-AzNetworkSecurityGroup -Name $NetworkSecurityGroupName -ResourceGroupName $ResourceGroupName

function AllowHostedAgentIP {    
    # Add IP to Network Security Group
    Try {        
        # Get Network security Group rule
        Write-Output "Checking if NSG rule '$RuleName' already exists."
        $networkSecurityGroupRule = $networkSecurityGroup | Get-AzNetworkSecurityRuleConfig -Name $RuleName -ErrorAction SilentlyContinue
        If ($networkSecurityGroupRule) {
            Write-Output "NSG rule found with name '$RuleName'. Removing NSG rule."

            Remove-AzNetworkSecurityRuleConfig -Name $RuleName -NetworkSecurityGroup $NetworkSecurityGroup
        }
        else {
            Write-Output "No NSG rule found matching name '$RuleName'"
        }

        Write-Output "Creating temporary firewall rule to allow Azure DevOps Hosted Agent access to resource"
        $networkSecurityGroup | `
            Add-AzNetworkSecurityRuleConfig -Name $RuleName -Description "Allow Azure DevOps Hosted Agent" `
            -Access Allow `
            -Protocol Tcp -Direction Inbound -Priority $Priority  -SourceAddressPrefix $agentIP `
            -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange * | `
            Set-AzNetworkSecurityGroup | Out-Null       
    }
    catch {
        $ErrorMsg = $_.Exception.Message
        $StatusDesc = $_.Exception.Response.StatusDescription                
        Throw $ErrorMsg + " " + $StatusDesc
    } 
}

function RemoveHostedAgentIP {
    # Remove IP from Network Security Group
    Try {
        Write-Output "Removing temporary firewall rule to allow Azure DevOps Hosted Agent access to resource"
        $networkSecurityGroup | Get-AzNetworkSecurityRuleConfig -Name $RuleName
        Remove-AzNetworkSecurityRuleConfig -Name $RuleName -NetworkSecurityGroup $NetworkSecurityGroup `
        | Set-AzNetworkSecurityGroup | Out-Null        
    }
    catch {
        $ErrorMsg = $_.Exception.Message
        $StatusDesc = $_.Exception.Response.StatusDescription                
        Throw $ErrorMsg + " " + $StatusDesc
    }    
}