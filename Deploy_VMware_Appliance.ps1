#requires -version 3
<#
.SYNOPSIS
  Powershell script to deploy VMware Appliances. 
 
.DESCRIPTION
  This script is to automate the deployment of VMware Appliances(OVF) to VMware vCenter and ESXi hosts
 
.PARAMETER configpath
  Path to the appliances deployment configuration.
 
.NOTES
  Version:        1.1
  Author:         David Balhrrie
  Last Updated:   04/08/14
  Creation Date:  27/07/14
.VERSION HISTORY
  1.1 04/08/14 Added option to control power on of vm
  1.0 27/07/14 Initial Version.
  
  
.EXAMPLE
  Deploy_VMware_Appliance.ps1 -configpath 'd:\config_file\vco_5_5_config_host.json'
  #>
param([Parameter(Mandatory=$true)][string]$configpath)

#===============================================================================
#Add in PowerCLI commands.
#===============================================================================
if ( (Get-PSSnapin -Name VMware.VimAutomation.Core -ErrorAction SilentlyContinue) -eq $null )
{
    add-pssnapin VMware.VimAutomation.Core
}


function Import-OVF
{
    param
    (
        [parameter(ValueFromPipeline=$true)] $deployType,
        [parameter(ValueFromPipeline=$true)] $deployConfig,
        [parameter(ValueFromPipeline=$true)] $parasArry
    )

    $ovftoolpaths = ("C:\Program Files (x86)\VMware\VMware OVF Tool\ovftool.exe","C:\Program Files\VMware\VMware OVF Tool\ovftool.exe")
    $ovftool = ''

    foreach ($ovftoolpath in $ovftoolpaths)
    {
        if(test-path $ovftoolpath)
        {
            $ovftool = $ovftoolpath
        }
    }
    if (!$ovftool)
    {
        write-host -ForegroundColor red "ERROR: OVFtool not found in it's standard path."
        write-host -ForegroundColor red "Edit the path variable or download ovftool here: http://www.vmware.com/support/developer/ovf/"
    }
    else
    {
        
        if ($deployType.ToLower() -eq "vcenter")
        {
            $moref = $vm.extensiondata.moref.value
            $session = Get-View -Id SessionManager
            $ticket = $session.AcquireCloneTicket()
            $parasArry += "--I:targetSessionTicket=$($ticket)"
            if ($deployConfig.powerOn -eq $true){
                $parasArry += "--powerOn"
            }
        }
        $parasArry += "--name="+$deployConfig.vmName
        $parasArry += "--datastore="+$deployConfig.datastore
        $parasArry += "--diskMode="+$deployConfig.diskMode
        $parasArry += "--network="+$deployConfig.network
        $parasArry += "--acceptAllEulas"
        $parasArry += $deployConfig.ovfpath
        
        if ($deployType.ToLower() -eq "vcenter")
        {
            $parasArry += "vi://$($defaultviserver.name)/?dns="+$deployConfig.host+"" 
        }
        else
        {
            $parasArry += "vi://"+$deployConfig.host_username+":"+$deployConfig.host_password+"@$($defaultviserver.name)/"
        }

        & $ovftool $parasArry

    }

}

function Get-Config {  
[CmdletBinding()]          
 Param              
   (
   [Parameter(Mandatory=$true)][String]$config_Path                        
     )#End Param 
     
    $jsonFile = Get-Content $config_Path -raw

    return $jsonFile | ConvertFrom-JSON
}

function Get-esxVersion { 

    foreach($prop in Get-view -ViewType HostSystem -Property Name, Config.Product | select {$_.Config.Product.Version})
    {  
      $esxVer = $prop.{$_.Config.Product.Version}
    }
    return $esxVer
}


#### Set-ovfProperties Based on https://github.com/lamw/vghetto-scripts/blob/master/powershell/setOvfEnv.ps1 ####
#### Author: William Lam http://www.virtuallyghetto.com ####
function Set-ovfProperties {
[CmdletBinding()]          
 Param              
   (
   [Parameter(Mandatory=$true)][String]$vmname,
   [Parameter(Mandatory=$true)][String]$esxVer, 
   [Parameter(Mandatory=$true)][String]$ovfParasArry                        
   )#End Param 


# Name of the OVF Env VM Adv Setting
$ovfenv_key = “guestinfo.ovfEnv”

# VCSA Example
$ovfvalue = "<?xml version=`"1.0`" encoding=`"UTF-8`"?> 
<Environment 
     xmlns=`"http://schemas.dmtf.org/ovf/environment/1`" 
     xmlns:xsi=`"http://www.w3.org/2001/XMLSchema-instance`" 
     xmlns:oe=`"http://schemas.dmtf.org/ovf/environment/1`" 
     xmlns:ve=`"http://www.vmware.com/schema/ovfenv`" oe:id=`"`" >
   <PlatformSection> 
      <Kind>VMware ESXi</Kind> 
      <Version>"+$esxVer+"</Version> 
      <Vendor>VMware, Inc.</Vendor> 
      <Locale>en</Locale> 
   </PlatformSection> 
   <PropertySection> 
         "+$ovfParasArry+"
   </PropertySection>
</Environment>"

# Adds "guestinfo.ovfEnv" VM Adv setting to VM
Get-VM $vmname | New-AdvancedSetting -Name $ovfenv_key -Value $ovfvalue -Confirm:$false -Force:$true

}


###### Get configuration from JSON file ######
if ((Test-Path $configpath) -eq $false)
{
    Write-host "The path to the configuration you provided doesn't exist" -ForegroundColor Red -BackgroundColor White
    break   
} 
$configObj = Get-Config -Config_Path $configPath
$parasArry = @()
$ovfParas 


$props = $configObj.config.properties 

if ($configObj.config.deployType.ToLower() -eq "vcenter")
{
    Write-host "**************** Connect to vCenter ****************"
    Connect-viserver  $configObj.config.deployConfig.vcenter -User  $configObj.config.deployConfig.vcenter_username -Password  $configObj.config.deployConfig.vcenter_password 
    Write-host "**************** Connected to vCenter ****************"
       
}
else
{
    Write-host "**************** Connect to ESXi Host ****************"
    Connect-viserver  $configObj.config.deployConfig.host -User  $configObj.config.deployConfig.host_username -Password  $configObj.config.deployConfig.host_password 
    Write-host "**************** Connected to ESXi Host ****************"

   $esxVer = Get-esxVersion     
}

foreach($prop in $props.psobject.properties | select name, value)
{  
  
    $parasArry += ("--prop:"+$prop.Name+"="+$prop.Value+" ")
    $ovfParas += '<Property oe:key="'+$prop.Name+'" oe:value="'+$prop.Value+'"/>'
}


Import-OVF -parasArry $parasArry -deployConfig $configObj.config.deployConfig -deployType $configObj.config.deployType

if ($configObj.config.deployType.ToLower() -eq "host")
{
    Set-ovfProperties -vmname $configObj.config.deployConfig.vmName -esxVer $esxVer -ovfParasArry $ovfParas | Out-Null
    if ($configObj.config.deployConfig.powerOn -eq $true){
        Start-VM -VM $configObj.config.deployConfig.vmName | Out-Null
    }
    
}

Write-host ("The VM " + $configObj.config.deployConfig.vmName + "has been deployed.")


Disconnect-VIServer -Force -confirm:$false