#
# ConfigurationDataSQL.psd1
#

@{ 
AllNodes = @( 
    @{ 
        NodeName					= "localhost" 
		PSDscAllowDomainUser		= $true
		PSDscAllowPlainTextPassword = $true
        
        
		#SQLSourcePath				= "F:\Source\SQL2014\SQLServer_12.0_Full\"
        SQLSourcePath				= "F:\Source\SQL2016\SQLServer_13.0_Full\"
        SQLFeatures					= "SQLENGINE,FullText"

        SXSPath                     = 'F:\Source\sxs'
        
		Role						= "PrimaryClusterNode"

        DisksPresent                = $null
		
		StoragePools                = @{ FriendlyName = 'DATA'   ; DriveLetter = 'F' ; LUNS = (0,1,2,3); ColumnCount = 2},
									  @{ FriendlyName = 'LOGS'   ; DriveLetter = 'G' ; LUNS = (8)},
									  @{ FriendlyName = 'TEMPDB' ; DriveLetter = 'H' ; LUNS = (12)},
									  @{ FriendlyName = 'BACKUP' ; DriveLetter = 'I' ; LUNS = (15)}

		WindowsFeatureSetPresent    = @( "RSAT-Clustering-PowerShell","RSAT-AD-PowerShell","RSAT-Clustering-Mgmt",
                                         "Failover-Clustering","NET-Framework-Core","RSAT-AD-AdminCenter" )
    
		WindowsFeatureSetAbsent    = 'FS-SMB1', 'BitLocker', 'EnhancedStorage'
        
		SQLSvcAccount               = 'svcAZSQL'
		

		UserRightsAssignmentPresent = @{identity = 'nt service\mssqlserver'
										policy = 'Perform_volume_maintenance_tasks'},

									 @{identity = 'nt service\mssqlserver'
										policy = 'Lock_pages_in_memory'},

									 @{identity = 'Contoso\svcAZSQL'
										policy = 'Perform_volume_maintenance_tasks'},

									 @{identity = 'Contoso\svcAZSQL'
										policy = 'Lock_pages_in_memory'}  
		
        SQLServerLogins             = @{Name = 'NT SERVICE\ClusSvc'}

		#SQLServerRoles              = @{ServerRoleName='sysadmin' ; MembersToInclude = 'SoftProNow\HSTDeploySVC' }

 		SQLServerPermissions        = @{Name       = 'NT SERVICE\ClusSvc' 
										Permission = 'AlterAnyAvailabilityGroup','ViewServerState'}
       
		DirectoryPresent            = 'F:\Source','F:\InstallFiles'

		DirectoryPresentSource      = @{filesSourcePath      = '\\{0}.file.core.windows.net\source\SQL2016\'
									    filesDestinationPath = 'F:\Source\SQL2016\'},
									  @{filesSourcePath      = '\\{0}.file.core.windows.net\source\SQLScripts\'
									    filesDestinationPath = 'F:\Source\SQLScripts\'}
        
                                      #@{filesSourcePath      = '\\{0}.file.core.windows.net\source\InstallFiles\SXS\'
									    #filesDestinationPath = 'F:\InstallFiles\SXS\'}
        

		SoftwarePackagePresent      = @{Name            = 'Microsoft SQL Server Management Studio - 17.3'
			                            Path            = 'F:\Source\SQL2016\SSMS-Setup-ENU.exe'
			                            ProductId       = ''
                                        Arguments       = '/install /quiet /norestart'}



        SQLServerScriptsPresent     = @{SetFilePath     = 'F:\Source\SQLScripts\BackupCreds\Set-BackupCreds.sql'
                                        GetFilePath     = 'F:\Source\SQLScripts\BackupCreds\Get-BackupCreds.sql'
                                        TestFilePath    = 'F:\Source\SQLScripts\BackupCreds\Test-BackupCreds.sql'},

                                      @{SetFilePath     = 'F:\Source\SQLScripts\TempDB\Set-TempDB.sql'
                                        GetFilePath     = 'F:\Source\SQLScripts\TempDB\Get-TempDB.sql'
                                        TestFilePath    = 'F:\Source\SQLScripts\TempDB\Test-TempDB.sql'}

		RegistryKeyPresent          = @{ Key = 'HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'; 
                                         ValueName = 'DontUsePowerShellOnWinX';	ValueData = 0 ; ValueType = 'Dword'},

                                      @{ Key = 'HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'; 
                                         ValueName = 'TaskbarGlomLevel';	ValueData = 1 ; ValueType = 'Dword'}                             
     }
 )
}
