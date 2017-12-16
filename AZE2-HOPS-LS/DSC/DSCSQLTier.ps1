Configuration Main
{
Param ( 
		[String]$DomainName = 'contoso.com',
		[PSCredential]$AdminCreds,
		[Int]$RetryCount = 20,
		[Int]$RetryIntervalSec = 120,
        [String]$ThumbPrint = '606295CAE217319DC730F8F1ABF3AEBEF636047B',
        [String]$StorageAccountKeySource,
		[String]$StorageAccountName = 'sacontosoglobaleus2',
		[String]$SQLInstanceName = 'MSSQLSERVER',
		[String]$SQLClusterName='CLST01',
		[String]$SQLClusterIP='10.144.143.216'
		)

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
Import-DscResource -ModuleName StoragePoolcustom
Import-DscResource -ModuleName SecurityPolicyDSC

$NetBios = $(($DomainName -split '\.')[0])
[PSCredential]$DomainCreds = [PSCredential]::New( $NetBios + '\' + $(($AdminCreds.UserName -split '\\')[-1]), $AdminCreds.Password )

Node $AllNodes.NodeName
{
    Write-Warning -Message "AllNodes"
    Write-Verbose -Message "Node is: [$($Node.NodeName)]" -Verbose
    Write-Verbose -Message "NetBios is: [$NetBios]" -Verbose
    Write-Verbose -Message "DomainName is: [$DomainName]" -Verbose

    # Allow this to be run against local or remote machine
    if($NodeName -eq "localhost") {
        [string]$computername = $env:COMPUTERNAME
    }
    else {
        Write-Verbose $Nodename.GetType().Fullname
        [string]$computername = $Nodename
    } 
    Write-Verbose -Message $computername -Verbose


    if ($Node.WindowsFeaturesSet)
    {
        $Node.WindowsFeaturesSet | foreach {
            Write-Verbose -Message $_ -Verbose -ErrorAction SilentlyContinue
        }
    }

	LocalConfigurationManager
    {
        ActionAfterReboot    = 'ContinueConfiguration'
        ConfigurationMode    = 'ApplyAndMonitor'
        RebootNodeIfNeeded   = $true
        AllowModuleOverWrite = $true
    }

   	foreach ($Pool in $Node.StoragePools)
	{
		StoragePool $Pool.DriveLetter
		{
			FriendlyName = ($SQLInstanceName + '_' + $Pool.FriendlyName)
			DriveLetter  = $Pool.DriveLetter
			LUNS         = $Pool.LUNS
            ColumnCount  = $(if ($Pool.ColumnCount) { $Pool.ColumnCount } else { 0 })
		}
		$dependsonStoragePoolsPresent += @("[xDisk]$($disk.DriveLetter)")
	}

	#-------------------------------------------------------------------

	xWaitForADDomain $DomainName
	{
		DomainName = $DomainName
		RetryCount = $RetryCount
		RetryIntervalSec = $RetryIntervalSec
		DomainUserCredential = $AdminCreds
	}

	xComputer DomainJoin
	{
		Name       = $computername
		DependsOn  = "[xWaitForADDomain]$DomainName"
		DomainName = $DomainName
		Credential = $DomainCreds
	}
    
	# reboots after DJoin
	xPendingReboot RebootForDJoin
	{
		Name      = 'RebootForDJoin'
		DependsOn = '[xComputer]DomainJoin'
		SkipComponentBasedServicing = $true
		SkipWindowsUpdate = $true
	}
	#-------------------------------------------------------------------

	xTimeZone EasternStandardTime
    { 
        IsSingleInstance = 'Yes'
        TimeZone         = "Eastern Standard Time" 
    }

    xDnsConnectionSuffix softpronow
    {
        InterfaceAlias                 = "*Ethernet*"
        RegisterThisConnectionsAddress = $true
        ConnectionSpecificSuffix       = $DomainName
    }
    #-------------------------------------------------------------------

    if ($Node.WindowsFeatureSetPresent)
    {
        WindowsFeatureSet WindowsFeatureSetPresent
        {
            Ensure = 'Present'
            Name   = $Node.WindowsFeatureSetPresent
            Source = $Node.SXSPath
        }
    }
    #-------------------------------------------------------------------
    Service ShellHWDetection
    {
        Name = 'ShellHWDetection'
        State = 'Stopped'
    }
    #-------------------------------------------------------------------
	foreach ($UserRightsAssignment in $Node.UserRightsAssignmentPresent)
    {
        UserRightsAssignment (($UserRightsAssignment.policy -replace $StringFilter) + ($UserRightsAssignment.identity -replace $StringFilter))
        {
            Identity     = $UserRightsAssignment.identity
            Policy       = $UserRightsAssignment.policy       
        }

        $dependsonUserRightsAssignment += @("[UserRightsAssignment]$($UserRightsAssignment.policy)")
    }
	#-------------------------------------------------------------------
    foreach ($RegistryKey in $Node.RegistryKeyPresent)
    {
			
        Registry $RegistryKey.ValueName
        {
            Key       = $RegistryKey.Key
            ValueName = $RegistryKey.ValueName
            Ensure    = 'Present'
            ValueData = $RegistryKey.ValueData
            ValueType = $RegistryKey.ValueType
            Force     = $true
			PsDscRunAsCredential = $DomainCreds
        }

        $dependsonRegistryKey += @("[Registry]$($RegistryKey.ValueName)")
    }
	#-------------------------------------------------------------------

      foreach ($disk in $Node.DisksPresent)
      {
         xDisk $disk.DriveLetter 
         {
            DiskID  = $disk.DiskNumber
			DriveLetter = $disk.DriveLetter
            AllocationUnitSize = 64KB
         }
         $dependsonDisksPresent += @("[xDisk]$($disk.DriveLetter)")
      }
  	  #-------------------------------------------------------------------

        #To clean up resource names use a regular expression to remove spaces, slashes an colons Etc.
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

		#-------------------------------------------------------------

		foreach ($PowerShellModule in $Node.PowerShellModulesPresent)
		{
		    PSModuleResource $PowerShellModule
		    {
                Module_Name = $PowerShellModule
                InstallScope = 'allusers'
		    }
		    $dependsonPowerShellModule += @("[File]$Name")
		}

		#-------------------------------------------------------------


		# base install above - custom role install


# ---------- SQL setup and install
    
      #-------------------------------------------------------------------

      foreach ($User in $Node.ADUserPresent)
      {
		xADUser $User.UserName
		{
			DomainName  = $User.DomainName
			UserName    = $User.Username
			Description = $User.Description
            Enabled     = $True
            Password    = $DomainCreds
            DomainController = $User.DomainController
            DomainAdministratorCredential = $DomainCreds
		}
		$dependsonUser += @("[xADUser]$($User.Username)")
	}
    #-------------------------------------------------------------------
    $SQLSvcAccount = $NetBios + '\' + $Node.SQLSvcAccount
    Write-Warning -Message "user `$SQLSvcAccount is: $SQLSvcAccount"
    [PSCredential]$SQLSvcAccountCreds = [PSCredential]::New( $SQLSvcAccount , $AdminCreds.Password)
    #write-warning -Message $SQLSvcAccountCreds.GetNetworkCredential().password
    
    # https://msdn.microsoft.com/en-us/library/ms143547(v=sql.120).aspx
    # File Locations for Default and Named Instances of SQL Server
    
    xSqlServerSetup xSqlServerInstall
    {
        SourcePath          = $Node.SQLSourcePath
		Action              = 'Install'
        PsDscRunAsCredential = $DomainCreds
        InstanceName        = $SQLInstanceName
        Features            = $Node.SQLFeatures
        SQLSysAdminAccounts = $SQLSvcAccount
        SQLSvcAccount       = $SQLSvcAccountCreds
		AgtSvcAccount       = $SQLSvcAccountCreds
        InstallSharedDir    = "F:\Program Files\Microsoft SQL Server"
        InstallSharedWOWDir = "F:\Program Files (x86)\Microsoft SQL Server"
        InstanceDir         = "F:\Program Files\Microsoft SQL Server"
        InstallSQLDataDir   = "F:\MSSQL\Data"
        SQLUserDBDir        = "F:\MSSQL\Data"
        SQLUserDBLogDir     = "G:\MSSQL\Logs"
        SQLTempDBDir        = "H:\MSSQL\Data"
        SQLTempDBLogDir     = "H:\MSSQL\Temp"                                                                  
        SQLBackupDir        = "I:\MSSQL\Backup"
        DependsOn           = $dependsonUser
		UpdateEnabled       = "true"
		UpdateSource        = ".\Updates"
		SecurityMode        = "SQL"
		SAPwd               = $SQLSvcAccountCreds
    }

    #-------------------------------------------------------------------

    xSQLServerMemory SetSQLServerMaxMemory
    {
        Ensure          = 'Present'
        DynamicAlloc    = $true
        SQLServer       = $computername
		SQLInstanceName = $SQLInstanceName
        PsDscRunAsCredential = $DomainCreds
        #MaxMemory = (105GB/1MB)
        #MinMemory = (50GB/1MB)
        DependsOn    = '[xSqlServerSetup]xSqlServerInstall'
    }

    xSQLServerMaxDop SetSQLServerMaxDopToAuto
    {
        Ensure          = 'Present'
        DynamicAlloc    = $false
        SQLServer       = $computername
		SQLInstanceName = $SQLInstanceName
        MaxDop          = 1
        DependsOn    = '[xSqlServerSetup]xSqlServerInstall'

    }

    #-------------------------------------------------------------------

    xSqlServerFirewall xSqlServerInstall
    {
        SourcePath   = $Node.SQLSourcePath
        InstanceName = $SQLInstanceName
        Features     = $Node.SQLFeatures
        DependsOn    = '[xSqlServerSetup]xSqlServerInstall'
    }

    
	# Note you need to open the firewall ports for both the probe and service ports
	# If you have multiple Availability groups for SQL, they need to run on different ports
	# e.g. 1433,1434,1435
	# e.g. 59999,59998,59997
	xFirewall ProbePorts
    {
        Name = 'ProbePorts'
        Action = 'Allow'
        Direction = 'Inbound'
        LocalPort = 59999,59998,59997
        Protocol = 'TCP'
    }

	xFirewall SQLPorts
    {
        Name = 'SQLPorts'
        Action = 'Allow'
        Direction = 'Inbound'
        LocalPort = 1433,1432,1431,5022
        Protocol = 'TCP'
        Profile = 'Domain','Private'
    }

	foreach ($userLogin in $Node.SQLServerLogins)
	{
		xSQLServerLogin $userLogin.Name
		{
			Ensure          = 'Present'
			Name            = $userLogin.Name
			LoginType       = 'WindowsUser'
			SQLServer       = $computername
			SQLInstanceName = $SQLInstanceName
			PsDscRunAsCredential = $SQLSvcAccountCreds
			DependsOn    = '[xSqlServerSetup]xSqlServerInstall'
		}
        $dependsonuserLogin += @("[xSQLServerLogin]$($userLogin.Name)")
    }

	foreach ($userRole in $Node.SQLServerRoles)
	{
		xSQLServerRole $userRole.ServerRoleName
		{
			Ensure           = 'Present'
            ServerRoleName   = $userRole.ServerRoleName
            MembersToInclude = $userRole.MembersToInclude
			SQLServer        = $computername
			SQLInstanceName  = $SQLInstanceName
			PsDscRunAsCredential = $SQLSvcAccountCreds
			DependsOn    = '[xSqlServerSetup]xSqlServerInstall'
		}
        $dependsonuserRoles += @("[xSQLServerRole]$($userRole.ServerRoleName)")
    }

	foreach ($userPermission in $Node.SQLServerPermissions)
	{
		# Add the required permissions to the cluster service login
		xSQLServerPermission $userPermission.Name
		{
			Ensure          = 'Present'
			NodeName        = $computername
			InstanceName    = $SQLInstanceName
			Principal       = $userPermission.Name
			Permission      = $userPermission.Permission
			PsDscRunAsCredential = $SQLSvcAccountCreds
			DependsOn            = '[xSqlServerSetup]xSqlServerInstall'
		}
		$dependsonSQLServerPermissions += @("[xSQLServerPermission]$($userPermission.Name)")
	}
      #-------------------------------------------------------------------
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
            DependsOn       = $dependsonWebSites + '[xSqlServerSetup]xSqlServerInstall'
            Arguments       = $Package.Arguments
		}

		$dependsonPackage += @("[xPackage]$($Name)")
	  }
      #-------------------------------------------------------------------
	  # Run and SQL scripts
      foreach ($Script in $Node.SQLServerScriptsPresent)
      {
		$i = $Script.ServerInstance -replace $StringFilter
		$Name = $Script.TestFilePath -replace $StringFilter
        $key = $StorageAccountKeySource -replace "=+$",""
        $eqCnt = $StorageAccountKeySource.Length - $key.Length

		xSQLServerScript ($i + $Name)
		{
            ServerInstance = $computername
            SetFilePath    = $Script.SetFilePath
            GetFilePath    = $Script.GetFilePath
            TestFilePath   = $Script.TestFilePath
			Variable       = "name=$StorageAccountName","key=$key","eqCnt=$eqCnt"
            PsDscRunAsCredential = $DomainCreds   
		}

		$dependsonSQLServerScripts += @("[xSQLServerScript]$($Name)")
	  }
      #------------------------------------------------------------------- 


	  
        # reboots after PackageInstall
        xPendingReboot PackageInstall
        {
            Name      = 'PackageInstall'
            DependsOn = $dependsonPackage
            SkipComponentBasedServicing = $true
            SkipWindowsUpdate = $true
        }

}

Node $AllNodes.Where{$_.Role -eq "PrimaryClusterNode"}.NodeName
{
    Write-Warning -Message "PrimaryClusterNode"
    Write-Verbose -Message "Node is: [$($computername)]" -Verbose
    Write-Verbose -Message "NetBios is: [$NetBios]" -Verbose
    Write-Verbose -Message "DomainName is: [$DomainName]" -Verbose
    $SQLSvcAccount = $NetBios + '\' + $Node.SQLSvcAccount
    Write-warning "user is: $SQLSvcAccount"
    [PSCredential]$SQLSvcAccountCreds = [PSCredential]::New( $SQLSvcAccount , $AdminCreds.Password)
    write-warning -Message $SQLSvcAccountCreds.UserName
    #write-warning -Message $SQLSvcAccountCreds.GetNetworkCredential().password

    # Allow this to be run against local or remote machine
    if($NodeName -eq "localhost") {
        [string]$computername = $env:COMPUTERNAME
    }
    else {
        Write-Verbose $Nodename.GetType().Fullname
        [string]$computername = $Nodename
    } 
    Write-Verbose -Message $computername -Verbose


		xCluster SQLCluster
		{
			Name            = $SQLClusterName
			StaticIPAddress = $SQLClusterIP
			DomainAdministratorCredential = $DomainCreds
			DependsOn = '[WindowsFeatureSet]WindowsFeatureSetPresent'
		}

<#        xClusterQuorum FailoverClusterQuorum
        {
            Type             = 'NodeAndFileShareMajority'
            Resource         = $Node.FileShareWitnessPath
            IsSingleInstance = 'Yes'
            DependsOn        ='[xCluster]SQLCluster'
            PsDscRunAsCredential = $DomainCreds
        }
#>
		xSQLServerAlwaysOnService SQLCluster
		{
			Ensure          = "Present"
			SQLServer       = $computername
			SQLInstanceName = $SQLInstanceName
			RestartTimeout  = 360
			DependsOn       = '[xCluster]SQLCluster'
		} 
       
       xSQLServerEndpoint SQLCluster
       {
            Ensure          = "Present"
            Port            = 5022
            EndPointName    = "Hadr_endpoint"
            SQLServer       = $computername
		    SQLInstanceName = $SQLInstanceName
            DependsOn       = '[xSQLServerAlwaysOnService]SQLCluster'
       }
	
        xSQLServerDatabase Create_Database
        {
            Ensure          = 'Present'
            SQLServer       = $computername
		    SQLInstanceName = $SQLInstanceName
            Name            = $NetBios
            DependsOn       = '[xSQLServerAlwaysOnService]SQLCluster'
        }
<#	
        xSQLServerAlwaysOnAvailabilityGroup ('AOAG' + $NetBios)
        {
            Ensure          = 'Present'
            Name            = ('AOAG' + $NetBios)
            SQLInstanceName = $SQLInstanceName
            SQLServer       = $computername
            DependsOn       = @('[xSQLServerEndpoint]SQLCluster') #+ $dependsonSQLServerPermissions
            PsDscRunAsCredential = $SQLSvcAccountCreds
	
        }

       xSQLServerAvailabilityGroupListener ($NetBios + '_LN')
       {
           AvailabilityGroup = ('AOAG' + $NetBios)
           InstanceName      = $SQLInstanceName
           Name              = ($NetBios + '_LN')
           NodeName          = $computername
           DHCP              = $false
           Ensure            = 'Present'
           IpAddress         = $Node.AvailabilityGroupListenerIP
           Port              = 1433
           DependsOn         = "[xSQLServerAlwaysOnAvailabilityGroup]$('AOAG' + $NetBios)"
       }
#>     



}#Node-PrimaryClusterNode

Node $AllNodes.Where{$_.Role -eq "ReplicaServerNode2"}.NodeName
{
        Write-Warning -Message "ReplicaServerNode"
        Write-Verbose -Message "Node is: [$($ENV:ComputerName)]" -Verbose
        Write-Verbose -Message "NetBios is: [$NetBios]" -Verbose
        Write-Verbose -Message "DomainName is: [$DomainName]" -Verbose
        $SQLSvcAccount = $NetBios + '\' + $Node.SQLSvcAccount
        Write-warning "user is: $SQLSvcAccount"
        [PSCredential]$SQLSvcAccountCreds = [PSCredential]::New( $SQLSvcAccount , $AdminCreds.Password)
        write-warning -Message $SQLSvcAccountCreds.UserName
        #write-warning -Message $SQLSvcAccountCreds.GetNetworkCredential().password
    
    # Allow this to be run against local or remote machine
    if($NodeName -eq "localhost") {
        [string]$computername = $env:COMPUTERNAME
    }
    else {
        Write-Verbose $Nodename.GetType().Fullname
        [string]$computername = $Nodename
    } 
    Write-Verbose -Message $computername -Verbose


	  #  xWaitForCluster TECluster
	  #  {
	  #  	Name                 = $SQLClusterName
	  #  	DependsOn            = '[WindowsFeatureSet]Commonroles'
	  #  	RetryIntervalSec     = 30
	  #  	RetryCount           = 20
	  #  }
	    
       # Join the cluster from the SQL1
	   # xCluster SQLCluster
	   # {
	   # 	Name            = $SQLClusterName
	   # 	StaticIPAddress = $SQLClusterIP
	   # 	DomainAdministratorCredential = $DomainCreds
	   # 	DependsOn                     = '[WindowsFeatureSet]Commonroles'
       #    PsDscRunAsCredential          = $DomainCreds  
	   # }

	 #   xSQLServerAlwaysOnService SQLCluster
	 #   {
	 #   	Ensure          = "Present"
	 #   	SQLServer       = $computername
	 #   	SQLInstanceName = $SQLInstanceName
	 #   	RestartTimeout  = 360
	 #   	DependsOn       = '[xWaitForCluster]TECluster'
	 #   } 
     #      
	 #   xSQLServerEndpoint SQLCluster
	 #   {
     #       Ensure         = "Present"
     #       Port           = 5022
     #       AuthorizedUser = $SQLSvcAccount
     #       EndPointName   = "Hadr_endpoint"
     #       DependsOn      = '[xWaitForCluster]TECluster'
     #       SQLServer       = $computername
	 #   	SQLInstanceName = $SQLInstanceName
	 #   }

        

	 # Do the availability groups as part of manual steps.

     #   xWaitForAvailabilityGroup AOGroup1
     #   {
     #       Name             = "AOGroup1"
     #       RetryIntervalSec = 30
     #       RetryCount       = 20
     #       DependsOn        = '[xSQLServerAlwaysOnService]SQLCluster','[xCluster]SQLCluster'
     #   }
     #   
     #   xSQLAOGroupJoin AOGroup1
     #   {
     #       Ensure                = 'Present'
     #       AvailabilityGroupName = "AOGroup1"
     #       DependsOn             = '[xWaitForAvailabilityGroup]AOGroup1'
	 #   	SQLServer             = $computername
	 #   	SQLInstanceName       = $SQLInstanceName
     #       #PsDscRunAsCredential  = $SQLSvcAccountCreds
     #       SetupCredential       = $SQLSvcAccountCreds
     #   }
     #
     #   xSQLServerAvailabilityGroupListener Group1listener
     #   {
     #       AvailabilityGroup = 'AOGroup1'
     #       InstanceName      = $SQLInstanceName
     #       Name              = 'Group1Listener'
     #       NodeName          = $computername
     #       DHCP              = $false
     #       Ensure            = 'Present'
     #       IpAddress         = 10.0.1.100
     #       Port              = 59999
     #       DependsOn         = '[xSQLAOGroupJoin]AOGroup1'
     #   }

}#Node-ReplicaServerNode
#>
}#Main

# used for troubleshooting
# F5 loads the configuration and starts the push

#region The following is used for manually running the script, breaks when running as system
if ((whoami) -match 'localadmin')
{
    Write-Warning -Message "no testing in prod !!!"
    if ($cred)
    {
        Write-Warning -Message "Cred is good"
    }
    else
    {
        $Cred = get-credential localadmin
    }

    # Set the location to the DSC extension directory
    $DSCdir = ($psISE.CurrentFile.FullPath | split-Path)
    if (Test-Path -Path $DSCdir -ErrorAction Ignore)
    {
        Set-Location -Path $DSCdir -ErrorAction Ignore
    }
}
else
{
    Write-Warning -Message "running as system"
    break
}
#endregion

<#
$Cred = get-credential LocalAdmin
#>


dir .\Main | Remove-Item
# main -ConfigurationData .\ConfigurationDataSQLx.psd1 -AdminCreds $cred -Verbose -StorageAccountKeySource $sak 
main -ConfigurationData .\*-ConfigurationData.psd1 -AdminCreds $cred -Verbose # -StorageAccountKeySource $sak 

#Set-DscLocalConfigurationManager -Path .\Main -Force -Verbose
Start-DscConfiguration -Path .\Main -Wait -Verbose -Force

break
$Cred = get-credential localadmin

Get-DscLocalConfigurationManager

Start-DscConfiguration -UseExisting -Wait -Verbose -Force

Get-DscConfigurationStatus -All

$result = Test-DscConfiguration -Detailed
$result.resourcesnotindesiredstate
$result.resourcesindesiredstate


# Cannot join the other nodes until this Folder issue is fixed.

###Requires -module NTFSSecurity
# SQL1,SQL2,SQL3,SQL4,SQL5
icm -cn SQL2 -ScriptBlock {
install-module -name NTFSSecurity
    Get-Item -path 'C:\ProgramData\Microsoft\Crypto\RSA\MachineKeys' | foreach {
    
        $_ | Set-NTFSOwner -Account BUILTIN\Administrators
        $_ | Clear-NTFSAccess -DisableInheritance
        $_ | Add-NTFSAccess -Account 'EVERYONE' -AccessRights ReadAndExecute -InheritanceFlags None -PropagationFlags NoPropagateInherit
        $_ | Add-NTFSAccess -Account BUILTIN\Administrators -AccessRights FullControl -InheritanceFlags None -PropagationFlags NoPropagateInherit
        $_ | Add-NTFSAccess -Account 'NT AUTHORITY\SYSTEM' -AccessRights FullControl -InheritanceFlags None -PropagationFlags NoPropagateInherit
        $_ | Get-NTFSAccess
    }
}
break
# SQL1,SQL2,SQL3,SQL4,SQL5
icm -cn AZSQL101 -ScriptBlock {
    install-module -name NTFSSecurity
    dir -path 'C:\ProgramData\Microsoft\Crypto\RSA\MachineKeys'  | foreach {
        Write-Verbose $_.fullname -Verbose
        $_ | Clear-NTFSAccess -DisableInheritance 
        $_ | Set-NTFSOwner -Account BUILTIN\Administrators
        $_ | Add-NTFSAccess -Account 'EVERYONE' -AccessRights ReadAndExecute -InheritanceFlags None -PropagationFlags NoPropagateInherit
        $_ | Add-NTFSAccess -Account BUILTIN\Administrators -AccessRights FullControl -InheritanceFlags None -PropagationFlags NoPropagateInherit
        $_ | Add-NTFSAccess -Account 'NT AUTHORITY\SYSTEM' -AccessRights FullControl -InheritanceFlags None -PropagationFlags NoPropagateInherit
        
        $_ | Get-NTFSAccess
   
    }
}



break
icm -cn SQL1,SQL2,SQL3,SQL4,SQL5 -ScriptBlock {
 #install-module -name NTFSSecurity -force -Verbose
 get-module -name NTFSSecurity -ListAvailable
 }

 # Confirm that the Cluster Probeport is set on the Service

 $ClusterNetworkName = "Cluster Network 1" # the cluster network name (Use Get-ClusterNetwork on Windows Server 2012 of higher to find the name)
$IPResourceName = "TestAG_10.0.1.100" # the IP Address resource name
$ILBIP = "10.0.1.100" # the IP Address of the Internal Load Balancer (ILB). This is the static IP address for the load balancer you configured in the Azure portal.
[int]$ProbePort = 59999

Import-Module FailoverClusters
Get-ClusterResource $IPResourceName | Set-ClusterParameter -Multiple @{"Address"="$ILBIP";"ProbePort"=$ProbePort;"SubnetMask"="255.255.255.0";"Network"="$ClusterNetworkName";"EnableDhcp"=0}

