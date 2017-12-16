#
# ConfigurationData.psd1
#

@{ 
AllNodes = @( 
    @{ 
        NodeName = "LocalHost" 
        PSDscAllowPlainTextPassword = $true
		PSDscAllowDomainUser = $true
        
        DirectoryPresent         = 'F:\InstallFiles','F:\domains\'
        InstallDir               = 'F:\InstallFiles'
        DisksPresent             = @{DriveLetter="F"; DiskId = "2"}
        
        InstallColdFusion        = $false
		
        

        # IncludesAllSubfeatures
		#WindowsFeaturePresent    = 'Web-Server','RSAT'
 
		# Single set of features
		#WindowsFeatureSetPresent = 'Web-Mgmt-Console'

		WindowsFeatureSetAbsent    = 'FS-SMB1', 'BitLocker', 'EnhancedStorage'

		DirectoryPresentSource  = @{filesSourcePath      = '\\{0}.file.core.windows.net\source\InstallFiles\OMSDependencyAgent\'
                                   filesDestinationPath = 'F:\InstallFiles\OMSDependencyAgent\'}
		
		SoftwarePackagePresent    = @{ Name            = 'Dependency Agent'
			                          Path            = 'F:\InstallFiles\OMSDependencyAgent\InstallDependencyAgent-Windows.exe'
			                          ProductId       = ''
                                      Arguments       = '/S'}

		RegistryKeyPresent          = @{ Key = 'HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'; 
                                         ValueName = 'DontUsePowerShellOnWinX';	ValueData = 0 ; ValueType = 'Dword'},

                                      @{ Key = 'HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'; 
                                         ValueName = 'TaskbarGlomLevel';	ValueData = 1 ; ValueType = 'Dword'}
				 
     } 
 )
}
