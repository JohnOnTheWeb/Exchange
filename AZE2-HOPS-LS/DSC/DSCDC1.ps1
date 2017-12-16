Configuration Main
{
Param ( 
		[String]$DomainName = 'contoso.com',
		[PSCredential]$AdminCreds,
		[String]$StorageAccountKeySource,
		[String]$StorageAccountName = 'sacontosoglobaleus2',
		[String]$NetworkID,
		[Int]$RetryCount = 15,
		[Int]$RetryIntervalSec = 60
		)

Import-DscResource -ModuleName PSDesiredStateConfiguration
Import-DscResource -ModuleName xPSDesiredStateConfiguration
Import-DscResource -ModuleName xActiveDirectory 
Import-DscResource -ModuleName xStorage
Import-DscResource -ModuleName xPendingReboot
Import-DscResource -ModuleName xTimeZone
Import-DscResource -ModuleName xDnsServer 

[PSCredential]$DomainCreds = New-Object System.Management.Automation.PSCredential ("$DomainName\$($AdminCreds.UserName)", $AdminCreds.Password)

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

    WindowsFeature InstallADDS
    {            
        Ensure = "Present"
        Name = "AD-Domain-Services"
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

    xADDomain DC1
    {
        DomainName = $DomainName
        DomainAdministratorCredential = $DomainCreds
        SafemodeAdministratorPassword = $DomainCreds
        DatabasePath = 'F:\NTDS'
        LogPath      = 'F:\NTDS'
        SysvolPath   = 'F:\SYSVOL'
        DependsOn = "[WindowsFeature]InstallADDS","[xDisk]FDrive"
    }

    xWaitForADDomain DC1Forest
    {
        DomainName           = $DomainName
        DomainUserCredential = $DomainCreds
        RetryCount           = $RetryCount
        RetryIntervalSec     = $RetryIntervalSec
        DependsOn = "[xADDomain]DC1"
    } 

    xADRecycleBin RecycleBin
    {
        EnterpriseAdministratorCredential = $DomainCreds
        ForestFQDN                        = $DomainName
        DependsOn = '[xWaitForADDomain]DC1Forest'
    }


	# when the DC is promoted the DNS (static server IP's) are automatically set to localhost (127.0.0.1 and ::1) by DNS
	# I have to remove those static entries and just use the Azure Settings for DNS from DHCP
	Script ResetDNS
    {
        DependsOn = '[xADRecycleBin]RecycleBin'
        GetScript = {@{Name='DNSServers';Address={Get-DnsClientServerAddress -InterfaceAlias Ethernet* | foreach ServerAddresses}}}
        SetScript = {Set-DnsClientServerAddress -InterfaceAlias Ethernet* -ResetServerAddresses -Verbose}
        TestScript = {Get-DnsClientServerAddress -InterfaceAlias Ethernet* -AddressFamily IPV4 | 
						Foreach {! ($_.ServerAddresses -contains '127.0.0.1')}}
    }

	#-------------------------------------------------------------------  
	
	$StringFilter = "\W",""
    
	write-verbose -Message "User is: [$StorageAccountName]"
	$StorageCred = [pscredential]::new( $StorageAccountName , (ConvertTo-SecureString -String $StorageAccountKeySource -AsPlainText -Force))
    


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

	# ADuser -------------------------------------------------------------------
	foreach ($User in $Node.ADUserPresent)
	{
		xADUser $User.UserName
		{
			DomainName  = $DomainName
			UserName    = $User.Username
			Description = $User.Description
			Enabled     = $True
			Password    = $DomainCreds
			#DomainController = $User.DomainController
			DomainAdministratorCredential = $DomainCreds
		}
		$dependsonUser += @("[xADUser]$($User.Username)")
	}

	# ADGroup -------------------------------------------------------------------
	foreach ($Group in $Node.ADGroupPresent)
	{
		xADGroup $Group.GroupName
		{
			Description      = $Group.Description
			GroupName        = $Group.GroupName
			GroupScope       = 'DomainLocal'
			MembersToInclude = $Group.MembersToInclude 			 
		}
		$dependsonADGroup += @("[xADGroup]$($Group.GroupName)")
	}

	# DNS Zone -------------------------------------------------------------------
	foreach ($DNSZone in $Node.DNSZones)
	{
		xDnsServerADZone $DNSZone.Name
		{
			Name               = $DNSZone.Name
			ReplicationScope   = 'Forest'
		}
		$dependsonDNSZone += @("[xDnsServerADZone]$($DNSZone.Name)")
	}

	# DNS Records -------------------------------------------------------------------
	foreach ($DnsRecord in $Node.DnsRecords)
	{
        if ($DnsRecord.Type -eq "ARecord")
        {
            $Target = $DnsRecord.Target -f $networkId   
        }
		else
		{
			$Target = $DnsRecord.Target -f $DomainName
		}       
		xDnsRecord ($DnsRecord.Name + $DnsRecord.Type)
		{
			Name       = $DnsRecord.Name
			Target     = $Target  
			Type       = $DnsRecord.Type
			Zone       = $DnsRecord.Zone
			DependsOn  = $dependsonDNSZone 
		}
		$dependsonDnsRecord += @("[xDnsARecord]$($DnsRecord.Name)")
	} 

    # Need to make sure the DC reboots after it is promoted.
	xPendingReboot RebootForPromo
    {
        Name      = 'RebootForDJoin'
        DependsOn = '[Script]ResetDNS'
    }

}
}#Main


