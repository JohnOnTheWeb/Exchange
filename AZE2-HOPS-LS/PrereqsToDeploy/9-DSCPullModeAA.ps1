break


#Get-AzureRmKeyVault
#Get-AzureRmStorageAccount | Select *Name

$AAName = "contosoAuto1"
$RGName = "contosoGlobal"
$env = "D"
$ConfigName = "DSCAppTier"
$kvname = "KeyValultEUS2"
$common = @{AutomationAccountName = $AAName;ResourceGroupName = $RGName; Verbose = $True; OV = "result"}



$ConfigurationPath = 'd:\azure'
$Configuration = @{
    SourcePath  = "$ConfigurationPath\$ConfigurationName.ps1"
    Description = 'A Test File'
    Published   = $True 
    Force       = $True
}


break

<# Don't need to upload, compiling mof locally #>

#1 Upload DSC Configuration to AA - DSCAppTier 

Import-AzureRmAutomationDscConfiguration @common -SourcePath $sourcepath -Force -Published


#2a Compile DSCAppTier to mof using configuration data

### GET CREDS FROM KEYVAULT ###
$ssAdmin = Get-AzureKeyVaultSecret -VaultName $kvname -Name LocalAdmin | foreach SecretValue
$localAdminCred = [PSCredential]::new("LocalAdmin",$ssAdmin)

$ssSA = Get-AzureKeyVaultSecret -VaultName $kvname -Name SourceFileStorageAccountKey | foreach SecretValueText

$sourcepath = ".\AZEUS2-MSFT-MTARM\DSC\DSCAppTier.ps1"
$configdatapath = ".\AZEUS2-MSFT-MTARM\CDAA\ALL-ConfigurationData.psd1"
$localAdminCred.UserName
$env
$mofdir = "C:\DSC\AA"

<#2b #>
$params = @{
    DomainName = "contoso.com"
    AdminCreds = $localAdminCred
    StorageAccountName = "sacontosoglobaleus2"
    StorageAccountKeySource = $ssSA
    ConfigurationData = $configdatapath 
    OutputPath = $mofdir
    Verbose = $True
}

. $sourcepath
Get-ChildItem -Path $mofdir -Filter *.mof | Remove-Item -ea 0
DSCAppTier @params 
Get-ChildItem -Path $mofdir -Filter *.meta.mof | Remove-Item -ea 0

Get-ChildItem -Path $mofdir -Filter *.mof |
Move-Item -Destination {($_.DirectoryName + "\" + $_.BaseName + "_" + $env + $_.Extension)} -PassThru -OutVariable mofs



#2c  Compile mofs local and upload mofs to AA
$params1 = @{ConfigurationName = $ConfigName;Force = $True}
# CMB|MYO|OCR|PCS|PDE
$mofs | where name -match "WEB|SVC" | foreach {
    #Get-AzureRmAutomationDscNodeConfiguration -ResourceGroupName $RGName -AutomationAccountName $AAName 
    Import-AzureRmAutomationDscNodeConfiguration @common @params1 -Path $_.FullName 
}


#3 Compiling mofs in AA
$configdata = (Join-Path -Path ($mofdir | Split-Path) -ChildPath "ALL-ConfigurationData.ps1")
copy-item -path $configdatapath -Destination $configdata
$cd = iex $configdata
$cd.AllNodes | foreach {if($_.nodename -notmatch "_") {$_.nodename = $_.nodename + "_$env"}}

$paramsAACompile = @{   
    DomainName = "contoso.com"
    StorageAccountName = "sacontosoglobaleus2"
    StorageAccountKeySource = $ssSA
}


Start-AzureRmAutomationDscCompilationJob @common -ConfigurationName $ConfigName -ConfigurationData $cd  -Parameters $paramsAACompile
$Job = $Result.Id.Guid

while ($Result.Status -ne 'Completed')
{
    # Review the compilation job, make sure it completed compiling to MOF
    Get-AzureRmAutomationDscCompilationJob @common -Id $job
    Sleep -Seconds 5
}




#4 Assign individual DSC configs to nodes
$paramfile = ".\AZEUS2-MSFT-MTARM\azuredeploy.1-dev.parameters.json"
$pfd = Get-Content -Path $paramfile  | ConvertFrom-Json | foreach parameters
$pfd.DeploymentInfo.value.AppServers | Select -Index 1 | foreach {
    $vm = $_.VMName.ToString()
    #$vm #| GM
    $vmname =  "AZE2-D3-MSFT-vm$vm"
    $NCName = $ConfigName + "." + $env + "_" + $_.ASName
    
    "Register-AzureRmAutomationDscNode"
    "vmname: $vmname"
    "NCName: $NCName"
    

    ""
    Register-AzureRmAutomationDscNode @common -AzureVMName $vmname -NodeConfigurationName $NCName -RebootNodeIfNeeded $true
    #break
}



$common


Import-AzureRmAutomationDscNodeConfiguration -Path "C:\DSC\AA\SVC_D.mof" -ConfigurationName "DSCAppTier" @common -Force -Debug