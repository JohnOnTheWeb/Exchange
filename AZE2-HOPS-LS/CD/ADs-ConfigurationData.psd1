#
# ConfigurationData.psd1
#

@{ 
AllNodes = @( 
    @{ 
        NodeName = "LocalHost" 
        PSDscAllowPlainTextPassword = $true
		PSDscAllowDomainUser = $true

		WindowsFeatureSetAbsent    = 'FS-SMB1'

		DirectoryPresentSource  = @{filesSourcePath      = '\\{0}.file.core.windows.net\source\OMSDependencyAgent\'
                                   filesDestinationPath = 'F:\Source\OMSDependencyAgent\'}
		
		SoftwarePackagePresent    = @{ Name            = 'Dependency Agent'
			                          Path            = 'F:\Source\OMSDependencyAgent\InstallDependencyAgent-Windows.exe'
			                          ProductId       = ''
                                      Arguments       = '/S'}

		RegistryKeyPresent          = @{ Key = 'HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'; 
                                         ValueName = 'DontUsePowerShellOnWinX';	ValueData = 0 ; ValueType = 'Dword'},

                                      @{ Key = 'HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'; 
                                         ValueName = 'TaskbarGlomLevel';	ValueData = 1 ; ValueType = 'Dword'}
     } 
 )
}
