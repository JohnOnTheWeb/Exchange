#
# ConfigurationData.psd1
#

@{ 
AllNodes = @( 
    @{ 
        NodeName = "LocalHost" 
        PSDscAllowPlainTextPassword = $true
		PSDscAllowDomainUser = $true
		

        WindowsFeatureSetPresent   = 'RSAT-DNS-Server'

		WindowsFeatureSetAbsent     = 'FS-SMB1'

		StoragePools                = @{ FriendlyName = 'DATA'   ; DriveLetter = 'F' ; LUNS = (0)}

		DirectoryPresent            = 'F:\InstallFiles','F:\Repository\WebImages','F:\Edge','F:\EdgeMail'

		SmbSharePresent             = @{ Name = "Repository" ;  Path = 'F:\Repository'},
									  @{ Name = "Edge" ;  Path = 'F:\Edge'},
									  @{ Name = "EdgeMail" ;  Path = 'F:\EdgeMail'}

		#DnsRecordsCustom              = @{Name = "nas-01";Target = "NACPFILE1.Contoso.com"; Type="CName"; Zone = "Contoso.com"}


		RegistryKeyPresent          = @{ Key = 'HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'; 
                                         ValueName = 'DontUsePowerShellOnWinX';	ValueData = 0 ; ValueType = 'Dword'},

                                      @{ Key = 'HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'; 
                                         ValueName = 'TaskbarGlomLevel';	ValueData = 1 ; ValueType = 'Dword'}
     } 
 )
}
