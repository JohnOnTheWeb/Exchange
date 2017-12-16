Configuration Main
{

Param ( [string] $nodeName )

Import-DscResource -ModuleName PSDesiredStateConfiguration
Import-DscResource -ModuleName xPSDesiredStateConfiguration
Import-DscResource -ModuleName xComputerManagement
Import-DscResource -ModuleName xActiveDirectory
Import-DscResource -ModuleName xStorage
Import-DscResource -ModuleName xPendingReboot
Import-DscResource -ModuleName xWebAdministration 
Import-DscResource -ModuleName xSQLServer
Import-DscResource -ModuleName xFailoverCluster
Import-DscResource -ModuleName xnetworking
Import-DscResource -ModuleName xTimeZone
Import-DscResource -ModuleName PowerShellModule
#Import-DscResource -ModuleName StoragePoolcustom
Import-DscResource -ModuleName SecurityPolicyDSC

Node $nodeName
  {
	   # Allow this to be run against local or remote machine
 #   if($NodeName -eq "localhost") {
 #       [string]$computername = $env:COMPUTERNAME
 #   }
 #   else {
 #       Write-Verbose $Nodename.GetType().Fullname
 #       [string]$computername = $Nodename
 #   } 
	#Write-Verbose -Message $computername -Verbose

	#  LocalConfigurationManager
 #   {
 #       ActionAfterReboot    = 'ContinueConfiguration'
 #       ConfigurationMode    = 'ApplyAndMonitor'
 #       RebootNodeIfNeeded   = $true
 #       AllowModuleOverWrite = $true
 #   }
 # WindowsFeature MSMQ
 #       {
	#		 Name = "MSMQ"

 #           Ensure = "Present"
	#	}

	#WindowsFeature MSMQ-services
 #       {
	#		 Name = "MSMQ-Services"

 #           Ensure = "Present"
	#	}
	# WindowsFeature MSMQ-server
 #       {
	#		 Name = "MSMQ-Server"

 #           Ensure = "Present"
	#	}

	#  WindowsFeature MSMQ-Directory
 #       {
	#		 Name = "MSMQ-Directory"

 #           Ensure = "Present"
	#	}
  }
}