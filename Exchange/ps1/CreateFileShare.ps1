Param (
  [Parameter()]
  [String]$SAKey,
  [String]$SAName
)
 #$VerbosePreference = "Continue"
 #Write-Verbose "Starting creation of file share $SAName"
Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
#Write-Verbose "Nuget Installed"


Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
Install-Module Azure -Confirm:$False
Import-Module Azure
#Write-Verbose "PS Gallery COnfigured"

$storageContext = New-AzureStorageContext -StorageAccountName $SAName -StorageAccountKey $SourceSAKey
#Write-Verbose "Storage Context Set"
$storageContext |  New-AzureStorageShare -Name 'ExchangeFiles'
#Write-Verbose "Fileshare created"