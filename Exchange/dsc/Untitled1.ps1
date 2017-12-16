#$PSVersionTable
configuration Myfiletest1
{
Param(
    [switch]$directory ,$COMPUTERNAME


)
    Import-DscResource -ModuleName psdesiredstateconfiguration
    node ($COMPUTERNAME)
    {
        if ($directory)
        {$type='Directory'}
        else
        {$type='File'} 

        File test1{
            Type = $type
            destinationpath='c:\test'
            Ensure = 'Present'
         }
    }
}
Myfiletest1 -directory -COMPUTERNAME $env:COMPUTERNAME
Start-DscConfiguration -path c:\Myfiletest1 -Wait -Verbose -Force