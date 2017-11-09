Param (
  [Parameter()]
  [String]$SAKey,
  [String]$SAName
)
Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
Install-Module Azure -Confirm:$False
Import-Module Azure
$storageContext = New-AzureStorageContext -StorageAccountName $SAName -StorageAccountKey $SourceSAKey
$storageContext |  New-AzureStorageShare -Name 'ExchangeFiles'