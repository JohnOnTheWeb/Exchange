Configuration ExchangeWebServer
{
	 $VerbosePreference = "Continue"
  param ($MachineName)
 Import-DscResource -ModuleName PSDesiredStateConfiguration
	Write-Verbose "Ddesired state module loaded"

  Node localhost
  {
	  LocalConfigurationManager
    {
      RebootNodeIfNeeded = $true
		}
    }
    #Install the IIS Role

    WindowsFeature IIS
    {
      Ensure = “Present”
      Name = “Web-Server”
    }

    #Install ASP.NET 4.5
    WindowsFeature ASP
    {
      Ensure = “Present”
      Name = “Web-Asp-Net45”
    }

     WindowsFeature WebServerManagementConsole
    {
        Name = "Web-Mgmt-Console"
        Ensure = "Present"
    }
  }
}