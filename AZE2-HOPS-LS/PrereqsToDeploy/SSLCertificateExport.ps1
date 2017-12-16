$cert=dir Cert:\LocalMachine\My
$Selectedcerts=$cert |select * | ogv -PassThru

break
$pw=read-host -AsSecureString

"Cannot Be Exported" > C:\DRV\CERT\CannotExport.txt
$Selectedcerts | foreach {
If ($_.friendlyname)
{
    $file=$_.Friendlyname -replace ",|\=|\.|\s|\*|\`"",""
}
else
{
    $file=$_.Subject -replace ",|\=|\.|\s|\*|\`"",""
}
$filepath=Join-Path -Path C:\DRV\CERT -ChildPath ($file + ".pfx")
#$filepath
try {
    Export-PfxCertificate -Password $pw -FilePath $filepath -Cert $_.pspath -ErrorAction Stop
}
catch {
    Write-Warning $file
    $file >> C:\DRV\CERT\CannotExport.txt    
}
}
