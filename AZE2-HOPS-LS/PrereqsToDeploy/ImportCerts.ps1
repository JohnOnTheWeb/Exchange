
dir -Path F:\source\Certs -Filter *.pfx | foreach {
Import-PfxCertificate -FilePath $_.FullName -Password $pw -CertStoreLocation Cert:\LocalMachine\My
}

Break
$pw=read-host -AsSecureString