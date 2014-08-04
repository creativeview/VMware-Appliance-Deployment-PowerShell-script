VMware Appliance Deployment PowerShell script
=============================================

##Overview
This script is to automate the deployment of VMware Appliances(OVF) to VMware vCenter and ESXi hosts. Example configuration files for deployment of VMware vCenter and vCO Appliances are provided in the example configurations folder. The script should be able to deploy any appliance that needs configuration details provided. 

##Prerequisites
- Microsoft PowerShell 3 + 
- [VMware vSphere PowerCLI](https://my.vmware.com/web/vmware/details?downloadGroup=PCLI550R2&productId=352) 
- [VMware OVF Tool] (https://www.vmware.com/support/developer/ovf/)

##Usage

Sample of how to run the script: 
```powershell
.\Deploy_VMware_Appliance.ps1 -configpath "D:\configuration\vco_5_5_config_host.json"
```

####Example configuration file for appliance deployment to host
Note don't change the `vm.vmname` property.

```json
{
    "config": {
        "deployType": "host",
        "deployConfig": {
            "host": "192.168.10.51",
			"host_username": "root",
            "host_password": "password",
			"vmName": "vcsa",
			"datastore": "DS1",
			"diskMode": "thin",
			"network": "VM Network",
			"powerOn": true,
			"ovfpath": "D:\\Mware-vCenter-Server-Appliance-5.5.0.5100-1312297_OVF10.ova"
        },
        "properties": 
            {
			"vami.DNS.VMware_vCenter_Server_Appliance":"192.168.10.55",
			"vami.gateway.VMware_vCenter_Server_Appliance":"192.168.10.1",
			"vami.hostname":"vcsa.domain.local",
			"vami.ip0.VMware_vCenter_Server_Appliance":"192.168.10.56",
			"vami.netmask0.VMware_vCenter_Server_Appliance":"255.255.255.0",
            "vm.vmname":"VMware_vCenter_Server_Appliance"
			}
    }
}
```

####Example configuration file for appliance deployment to VMware vCenter
Note don't change the `vm.vmname` property.

```json
{
    "config": {
        "deployType": "vcenter",
        "deployConfig": {
            "vcenter": "192.168.10.50",
            "vcenter_username": "administrator@vsphere.local",
            "vcenter_password": "password",
            "host": "192.168.10.51",
			"vmName": "VCO01",
			"datastore": "DS1",
			"diskMode": "thin",
			"network": "VM Network",
			"ovfpath": "D:\\VMware-vCO-Appliance-5.5.1.0-1617225_OVF10.ova"
        },
        "properties": 
            {
			"varoot-password":"password",
            "vcoconf-password":"password",
            "vami.hostname":"VCO01.domain.local",
            "vami.ip0.VMware_vCenter_Orchestrator_Appliance":"192.168.10.57",
			"vami.netmask0.VMware_vCenter_Orchestrator_Appliance":"255.255.255.0",
			"vami.gateway.VMware_vCenter_Orchestrator_Appliance":"192.168.10.1",
			"vami.DNS.VMware_vCenter_Orchestrator_Appliance":"192.168.10.55",
            "vm.vmname":"VMware_vCenter_Orchestrator_Appliance"
			}
    }
}
```

##More Information
For more information please read the following blog post: http://creativeview.co.uk/vmware-appliance-deployment-powershell-script/
