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

	 Node "localhost"
  {
	 # LocalConfigurationManager
  #  {
  #    RebootNodeIfNeeded = $true
		#}
    #INSTALL msmq
	   WindowsFeature MSMQ
        {
			 Name = "MSMQ"

            Ensure = "Present"
		}

	WindowsFeature MSMQ-services
        {
			 Name = "MSMQ-Services"

            Ensure = "Present"
		}
	 WindowsFeature MSMQ-server
        {
			 Name = "MSMQ-Server"

            Ensure = "Present"
		}

	  WindowsFeature MSMQ-Directory
        {
			 Name = "MSMQ-Directory"

            Ensure = "Present"
		}



    #Install the IIS Role

    WindowsFeature WebServerRole
        {
            Name = "Web-Server"
            Ensure = "Present"
        }

	 
        WindowsFeature WebAppDev

        {

            Name = "Web-App-Dev"

            Ensure = "Present"


            DependsOn = "[WindowsFeature]WebServerRole"

            }

	   WindowsFeature WebAspNet45

        {

            Name = "Web-Asp-Net45"

            Ensure = "Present"

            Source = $Source

            DependsOn = "[WindowsFeature]WebServerRole"

            }

        WindowsFeature WebNetExt35

        {

            Name = "Web-Net-Ext"

            Ensure = "Present"

            DependsOn = "[WindowsFeature]WebServerRole"

            }

	   WindowsFeature WebNetExt45

        {

            Name = "Web-Net-Ext45"

            Ensure = "Present"

            DependsOn = "[WindowsFeature]WebServerRole"

            }

	  WindowsFeature WebFtpServer
	  {
		Name = "Web-Ftp-Server"

		Ensure = "Present"

        DependsOn = "[WindowsFeature]WebServerRole"
	  
	  }

	  WindowsFeature WebMgmtCompat
	  {
		Name = "Web-Mgmt-Compat"

		Ensure = "Present"

        DependsOn = "[WindowsFeature]WebServerRole"
	  
	  }

        WindowsFeature WebISAPIExt

        {

            Name = "Web-ISAPI-Ext"

            Ensure = "Present"


            DependsOn = "[WindowsFeature]WebServerRole"

            }

        WindowsFeature WebISAPIFilter

        {

            Name = "Web-ISAPI-Filter"

            Ensure = "Present"

 
            DependsOn = "[WindowsFeature]WebServerRole"

            }

        WindowsFeature WebLogLibraries

        {

            Name = "Web-Log-Libraries"

            Ensure = "Present"

            DependsOn = "[WindowsFeature]WebServerRole"

            }

        WindowsFeature WebRequestMonitor

        {

            Name = "Web-Request-Monitor"

            Ensure = "Present"

            DependsOn = "[WindowsFeature]WebServerRole"

            }

        WindowsFeature WebMgmtTools

        {

            Name = "Web-Mgmt-Tools"

            Ensure = "Present"

            DependsOn = "[WindowsFeature]WebServerRole"

            }

        WindowsFeature WebMgmtConsole

        {

            Name = "Web-Mgmt-Console"

            Ensure = "Present"

            DependsOn = "[WindowsFeature]WebServerRole"

            }

	  WindowsFeature WAS

        {

            Name = "WAS"

            Ensure = "Present"

            DependsOn = "[WindowsFeature]WebServerRole"

            }

	  WindowsFeature WASProcessModel

        {

            Name = "WAS-Process-Model"

            Ensure = "Present"

            DependsOn = "[WindowsFeature]WebServerRole"

            }

	   WindowsFeature WASNetEnvironment

        {

            Name = "WAS-NET-Environment"

            Ensure = "Present"

            DependsOn = "[WindowsFeature]WebServerRole"

            }

	  WindowsFeature WASConfigAPIs

        {

            Name = "WAS-Config-APIs"

            Ensure = "Present"

            DependsOn = "[WindowsFeature]WebServerRole"

            }
  }
Node $nodeName
  {
   <# This commented section represents an example configuration that can be updated as required.
    WindowsFeature WebServerRole
    {
      Name = "Web-Server"
      Ensure = "Present"
    }
    WindowsFeature WebManagementConsole
    {
      Name = "Web-Mgmt-Console"
      Ensure = "Present"
    }
    WindowsFeature WebManagementService
    {
      Name = "Web-Mgmt-Service"
      Ensure = "Present"
    }
    WindowsFeature ASPNet45
    {
      Name = "Web-Asp-Net45"
      Ensure = "Present"
    }
    WindowsFeature HTTPRedirection
    {
      Name = "Web-Http-Redirect"
      Ensure = "Present"
    }
    WindowsFeature CustomLogging
    {
      Name = "Web-Custom-Logging"
      Ensure = "Present"
    }
    WindowsFeature LogginTools
    {
      Name = "Web-Log-Libraries"
      Ensure = "Present"
    }
    WindowsFeature RequestMonitor
    {
      Name = "Web-Request-Monitor"
      Ensure = "Present"
    }
    WindowsFeature Tracing
    {
      Name = "Web-Http-Tracing"
      Ensure = "Present"
    }
    WindowsFeature BasicAuthentication
    {
      Name = "Web-Basic-Auth"
      Ensure = "Present"
    }
    WindowsFeature WindowsAuthentication
    {
      Name = "Web-Windows-Auth"
      Ensure = "Present"
    }
    WindowsFeature ApplicationInitialization
    {
      Name = "Web-AppInit"
      Ensure = "Present"
    }
    Script DownloadWebDeploy
    {
        TestScript = {
            Test-Path "C:\WindowsAzure\WebDeploy_amd64_en-US.msi"
        }
        SetScript ={
            $source = "https://download.microsoft.com/download/0/1/D/01DC28EA-638C-4A22-A57B-4CEF97755C6C/WebDeploy_amd64_en-US.msi"
            $dest = "C:\WindowsAzure\WebDeploy_amd64_en-US.msi"
            Invoke-WebRequest $source -OutFile $dest
        }
        GetScript = {@{Result = "DownloadWebDeploy"}}
        DependsOn = "[WindowsFeature]WebServerRole"
    }
    Package InstallWebDeploy
    {
        Ensure = "Present"  
        Path  = "C:\WindowsAzure\WebDeploy_amd64_en-US.msi"
        Name = "Microsoft Web Deploy 3.6"
        ProductId = "{ED4CC1E5-043E-4157-8452-B5E533FE2BA1}"
        Arguments = "ADDLOCAL=ALL"
        DependsOn = "[Script]DownloadWebDeploy"
    }
    Service StartWebDeploy
    {                    
        Name = "WMSVC"
        StartupType = "Automatic"
        State = "Running"
        DependsOn = "[Package]InstallWebDeploy"
    } #>
  }
}