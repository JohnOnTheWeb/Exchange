Configuration Main
{
Param ( 
		[String]$DomainName = 'contoso.com',
		[PSCredential]$AdminCreds,
		[String]$StorageAccountKeySource,
		[String]$StorageAccountName = 'sacontosoglobaleus2',
		[Int]$RetryCount = 30,
		[Int]$RetryIntervalSec = 120,
		[String]$SiteName = 'Default-First-Site-Name'
		)

Import-DscResource -ModuleName PSDesiredStateConfiguration
Import-DscResource -ModuleName xPSDesiredStateConfiguration
Import-DscResource -ModuleName xComputerManagement
Import-DscResource -ModuleName xActiveDirectory
Import-DscResource -ModuleName xStorage
Import-DscResource -ModuleName xPendingReboot
Import-DscResource -ModuleName xTimeZone

[PSCredential]$DomainCreds = New-Object System.Management.Automation.PSCredential ("$DomainName\$(($AdminCreds.UserName -split '\\')[-1])", $AdminCreds.Password)

Node $AllNodes.NodeName
{
    Write-Verbose -Message $Nodename -Verbose


	LocalConfigurationManager
    {
        ActionAfterReboot   = 'ContinueConfiguration'
        ConfigurationMode   = 'ApplyAndMonitor'
        RebootNodeIfNeeded  = $true
        AllowModuleOverWrite = $true
    }
	
	xTimeZone EasternStandardTime
    { 
        IsSingleInstance = 'Yes'
        TimeZone         = "Eastern Standard Time" 
    }

	WindowsFeatureSet RSAT
    {            
        Ensure = 'Present'
        Name   = 'AD-Domain-Services'
		IncludeAllSubFeature = $true
    }

    #-------------------------------------------------------------------
    if ($Node.WindowsFeatureSetAbsent)
    {
        WindowsFeatureSet WindowsFeatureSetAbsent
        {
            Ensure = 'Absent'
            Name   = $Node.WindowsFeatureSetAbsent
        }
    }

	xDisk FDrive
    {
        DiskID  = "2"
        DriveLetter = 'F'
    }

    xWaitForADDomain $DomainName
    {
        DependsOn  = '[WindowsFeatureSet]RSAT'
        DomainName = $DomainName
        RetryCount = $RetryCount
		RetryIntervalSec = $RetryIntervalSec
        DomainUserCredential = $AdminCreds
    }

	xComputer DomainJoin
	{
		Name       = $Env:COMPUTERNAME
		DependsOn  = "[xWaitForADDomain]$DomainName"
		DomainName = $DomainName
		Credential = $DomainCreds
	}

    # reboots after DJoin
	xPendingReboot RebootForDJoin
    {
        Name      = 'RebootForDJoin'
        DependsOn = '[xComputer]DomainJoin'
    }

	xADDomainController DC2
	{
		DependsOn    = '[xPendingReboot]RebootForDJoin'
		DomainName   = $DomainName
		DatabasePath = 'F:\NTDS'
        LogPath      = 'F:\NTDS'
        SysvolPath   = 'F:\SYSVOL'
        DomainAdministratorCredential = $DomainCreds
        SafemodeAdministratorPassword = $DomainCreds
		PsDscRunAsCredential = $DomainCreds
		SiteName = $SiteName
	} 

		$StringFilter = "\W",""
    
		write-verbose -Message "User is: [$StorageAccountName]"
		$StorageCred = [pscredential]::new( $StorageAccountName , (ConvertTo-SecureString -String $StorageAccountKeySource -AsPlainText -Force))

	#-------------------------------------------------------------------     
	foreach ($File in $Node.DirectoryPresentSource)
	{
		$Name = ($File.filesSourcePath -f $StorageAccountName) -replace $StringFilter
		File $Name
		{
			SourcePath      = ($File.filesSourcePath -f $StorageAccountName)
			DestinationPath = $File.filesDestinationPath
			Ensure          = 'Present'
			Recurse         = $true
			Credential      = $StorageCred  
		}
		$dependsonDirectory += @("[File]$Name")
	} 

	# install any packages without dependencies
    foreach ($Package in $Node.SoftwarePackagePresent)
    {
        $Name = $Package.Name -replace $StringFilter
        xPackage $Name
        {
            Name            = $Package.Name
            Path            = $Package.Path
            Ensure          = 'Present'
            ProductId       = $Package.ProductId
            RunAsCredential = $DomainCreds
            DependsOn       = $dependsonDirectory
            Arguments       = $Package.Arguments
        }

        $dependsonPackage += @("[xPackage]$($Name)")
    }

	# when the 2nd DC is promoted the DNS (static server IP's) are automatically set to localhost (127.0.0.1 and ::1) by DNS
	# I have to remove those static entries and just use the Azure Settings for DNS from DHCP
	Script ResetDNS
    {
        DependsOn = '[xADDomainController]DC2'
        GetScript = {@{Name='DNSServers';Address={Get-DnsClientServerAddress -InterfaceAlias Ethernet* | foreach ServerAddresses}}}
        SetScript = {Set-DnsClientServerAddress -InterfaceAlias Ethernet* -ResetServerAddresses -Verbose}
        TestScript = {Get-DnsClientServerAddress -InterfaceAlias Ethernet* -AddressFamily IPV4 | 
						Foreach {! ($_.ServerAddresses -contains '127.0.0.1')}}
    }

    # Need to make sure the DC reboots after it is promoted.
	xPendingReboot RebootForPromo
    {
        Name      = 'RebootForDJoin'
        DependsOn = '[Script]ResetDNS'
    }
}
}#Main


break

# used for troubleshooting

#$Cred = get-credential brw
main -ConfigurationData .\ConfigurationData.psd1 -AdminCreds $cred -Verbose
Start-DscConfiguration -Path .\Main -Wait -Verbose -Force

Get-DscLocalConfigurationManager

Start-DscConfiguration -UseExisting -Wait -Verbose -Force

Get-DscConfigurationStatus -All