
#$pw = Read-Host -AsSecureString
Get-ChildItem -Path f:\source\Certs\ -Filter *.pfx | foreach {
    Get-PfxData -FilePath $_.Fullname -Password $pw -ErrorAction SilentlyContinue | Foreach EndEntityCertificates | foreach {
        
        $FriendlyName = $_.friendlyname
        $thumbprint   = $_.Thumbprint

        $_.DnsNameList | foreach {
            
            "@{HostHeader='$($_.Unicode)';thumbprint='$($thumbprint)'; IPAddress='*';Name ='*';Port=80 ;Protocol='http'},"
            "@{HostHeader='$($_.Unicode)';thumbprint='$($thumbprint)'; IPAddress='*';Name ='*';Port=443;Protocol='https'},"

        }
    }
} 
