<#.DESCRIPTION
   Author: Sebastian Schlesinger 
   Date: 8/17/2017
			Script that will connect to a Vsphere enviroment yo update VMware tools for a list of servers.
            Results will be logged on a txt file and sent through email
            This example was tested with Windows Server 2012R2 and vsphere 6.0
            
            Pre-requirements:
            This will require to have PowerCli installed. 
            Define the follwing variables: 
            A)$Logpath = path to save log
            B)$ServerList = Path where the txt file with the server list is stored. This file should contain one server per line. Example:
            Server1
            Server2
            C)$PCA = Name of the PowerCli action
            D)$Users = Email recipients 
            E)$Fromemail = Source email address for report
            F)$Server = SMTP Server 

#>
Get-Module -ListAvailable VMware* | Import-Module | Out-Null
##Variables to define:
$LogPath = "C:\logs"
$ServerList = 'C:\ServerList1.txt'
$PCA = 'VMware Tools Upgrade'
#Mail Settings:
$users = "user@YourDomain.com" 
$fromemail = "PowerCli@YourDomain.com" 
$server = "mail.YourSmtp.com" 

###########################SCRIPT EXECUTION DO NOT MODIFY UNLESS YOU KNOW WHAT YOU ARE DOING###################################

#########Create Transcript of script for logging purposes - Edit the outpath according to your needs
$ErrorActionPreference = "Continue"
$date = get-date -f yyyy-MM-dd
$outPath = "$LogPath\VMwareToolsUpgrade_$date.txt" # This is the path to save the results
Start-Transcript -path $outPath



##--- Connect to Vcenter
write-verbose "Connecting to Vcenter"   -Verbose 
function Connect-VMware {
##This section contains the commands to connect to Vcenter Edit according to your enviroment---
# ------vSphere Targeting Variables tracked below------
$vCenterInstance = "Vcenter IP"
$vCenterUser = "User"
$vCenterPass = "Password"
# This section logs on to the defined vCenter instance above
Connect-VIServer $vCenterInstance -User $vCenterUser -Password $vCenterPass -WarningAction SilentlyContinue
}
Connect-VMware

##List current VMware tools status
write-verbose "Checking VMware tool status..."   -Verbose
$VMs = Get-Content $ServerList
foreach ($vm in $VMs){
$Tools = Get-VM $vm
$Tools | select -expandproperty ExtensionData | select -expandproperty guest | ft hostname,Tools*
}

##Updarede VMware tools
write-verbose "Starting with Upgrade.. depending on the number of VMs this could take several minutes"   -Verbose
$VMs = Get-Content $ServerList

foreach ($vm in $VMs){
write-verbose "Updating VMware tools for $VM" -Verbose
Update-Tools -VM $vm -NoReboot #-RunAsync
write-verbose "VMware tools update for $VM completed sucessfully"   -Verbose 
}

##List current VMware tools status
write-verbose "Checking VMware tool status after upgrade"   -Verbose
$VMs = Get-Content $ServerList
foreach ($vm in $VMs){
$Tools = Get-VM $vm
$Tools | select -expandproperty ExtensionData | select -expandproperty guest | ft hostname,Tools*
}


##--- Disconnect from Vcenter
write-verbose "Disconnecting from Vcenter"   -Verbose
Disconnect-VIServer -Confirm:$False
 

##--- Transcript Ends
Stop-Transcript

##---Send log information through email
write-verbose "Last step. Sending email report..."   -Verbose
$Body = Get-Content $outPath | Out-String
$CurrentTime = Get-Date
send-mailmessage -UseSsl  -from $fromemail -to $users -subject "PowerCli Action $PCA Completed at $CurrentTime"  -Body $Body  -priority Normal -smtpServer $server
 