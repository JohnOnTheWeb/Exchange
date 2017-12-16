#$PSVersionTable
configuration Myfiletest1
{
Param(
    

)
    Import-DscResource -ModuleName psdesiredstateconfiguration
     node $AllNodes.NodeName 
    {
        
        File test1{
            Type = 'Directory'
            destinationpath=$node.Path
            Ensure = 'Absent'
         }
    }
}

$CD = @{

    AllNodes = @(

        @{
            NodeName = $env:COMPUTERNAME
            Path = "c:\test"

            }

       

    )

}




Myfiletest1 -ConfigurationData $CD
Start-DscConfiguration -path c:\Myfiletest1 -Wait -Verbose -Force