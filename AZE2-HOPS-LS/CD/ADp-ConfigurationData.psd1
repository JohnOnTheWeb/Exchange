#
# ConfigurationData.psd1
#

@{ 
AllNodes = @( 
    @{ 
        NodeName = "LocalHost" 
        PSDscAllowPlainTextPassword = $true
		PSDscAllowDomainUser = $true

		ADUserPresent               = @{UserName         = "svcAZSQL"
                                        Description      = "Service Account for SQL"}

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
     
		DNSZones2                    =   @{Name = "fabrikam.com"}

		DNSRecords2                 =    #@{Name = "cftask";Target = "{0}.206"; Type="ARecord"; Zone = "Contoso.com"},
										#@{Name = "combine";Target = "{0}.203"; Type="ARecord"; Zone = "Contoso.com"},
										#@{Name = "hyperlink";Target = "{0}.204"; Type="ARecord"; Zone = "Contoso.com"},
										#@{Name = "instantdoc";Target = "{0}.207"; Type="ARecord"; Zone = "Contoso.com"},
										#@{Name = "ocr";Target = "{0}.201"; Type="ARecord"; Zone = "Contoso.com"},
										#@{Name = "pdesharp";Target = "{0}.202"; Type="ARecord"; Zone = "Contoso.com"},
										#@{Name = "taxes";Target = "{0}.205"; Type="ARecord"; Zone = "Contoso.com"},

										####ARecord =    @{Name="AZMBLD01";Target="{0}.126"; Type="ARecord"},
										#@{Name = "cftask";Target = "{0}.206"; Type="ARecord"; Zone = "Contoso.com"},

										# WAF Internal IP's
										@{Name = "CONNECTS";Target = "{0}.252"; Type="ARecord"; Zone = "Contoso.com"},
										@{Name = "MYORDERS";Target = "{0}.251"; Type="ARecord"; Zone = "Contoso.com"},
										@{Name = "XML";     Target = "{0}.250"; Type="ARecord"; Zone = "Contoso.com"},

										# WAF Internal IP's
										@{Name = "COMBINE";Target = "{0}.126"; Type="ARecord"; Zone = "Contoso.com"},
										@{Name = "OCR";Target = "{0}.125"; Type="ARecord"; Zone = "Contoso.com"},
										@{Name = "PDESHARP";     Target = "{0}.124"; Type="ARecord"; Zone = "Contoso.com"},

										# SQL ILBs Internal IP's
										@{Name = "SQLEDGE01";Target = "{0}.219"; Type="ARecord"; Zone = "Contoso.com"},
										@{Name = "SQLEDGE02";Target = "{0}.218"; Type="ARecord"; Zone = "Contoso.com"},
										@{Name = "SQLOCR01";Target = "{0}.217"; Type="ARecord"; Zone = "Contoso.com"}

										CName =    @{Name="NAS-01";Target="AZE2D3NATEFIL01.{0}"; Type="Cname"}

										#@{Name = "taxes";Target = "taxes.{0}"; Type="CName"; Zone = "contoso.com"}


										 
  } 
 )
}
