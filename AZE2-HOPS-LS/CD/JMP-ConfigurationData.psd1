#
# ConfigurationData.psd1
#

# Status tested, not deployed
# APPTier
# NACJMP

@{ 


AllNodes = @( 
    @{ 
        NodeName = "localhost" 
		PSDscAllowDomainUser = $true
        PSDscAllowPlainTextPassword = $true


        DirectoryPresent        = 'F:\InstallFiles'

        InstallDir              = 'F:\InstallFiles'

        # Include all subfeatures
		WindowsFeaturePresent   = 'RSAT'

        InstallColdFusion       = $False
		
        DisksPresent             = @{DriveLetter="F"; DiskId = "2"}

		DirectoryPresentSource  = @{filesSourcePath      = '\\{0}.file.core.windows.net\source\OpenSSH-Win32'
								  filesDestinationPath   = 'F:\source\OpenSSH-Win32'},

								 @{filesSourcePath      = '\\{0}.file.core.windows.net\install\SQLClient\SSMS-Setup-ENU.exe'
								  filesDestinationPath   = 'F:\install\SQLClient\SSMS-Setup-ENU.exe'}

		SoftwarePackagePresent3   =@{ Name            = 'Microsoft SQL Server Management Studio - 17.3'
			                         Path            = 'F:\install\SQLClient\SSMS-Setup-ENU.exe'
			                         ProductId       = ''
                                     Arguments       = '/install /quiet /norestart'}

		
		SoftwarePackagePresent2    = @{ Name            = 'Dependency Agent'
			                          Path            = 'F:\InstallFiles\OMSDependencyAgent\InstallDependencyAgent-Windows.exe'
			                          ProductId       = ''
                                      Arguments       = '/S'},

                                    @{
                                       Name            = 'Adobe Reader XI (11.0.10)'
			                          Path            = 'F:\InstallFiles\Adobe\AdbeRdr11010_en_US.exe'
			                          ProductId       = ''
                                      Arguments       = '/sAll'},

                                    @{
                                        Name            = 'Microsoft Office Professional Plus 2010'
			                            Path            = 'F:\InstallFiles\Office2010\office\setup.exe'
			                            ProductId       = '{90140000-0011-0000-0000-0000000FF1CE}'
                                        Arguments       = '/config F:\InstallFiles\Office2010\config.xml'}

		RegistryKeyPresent          = @{ Key = 'HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'; 
                                         ValueName = 'DontUsePowerShellOnWinX';	ValueData = 0 ; ValueType = 'Dword'},

                                      @{ Key = 'HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'; 
                                         ValueName = 'TaskbarGlomLevel';	ValueData = 1 ; ValueType = 'Dword'}   
                               

     }#Localhost
)
}
