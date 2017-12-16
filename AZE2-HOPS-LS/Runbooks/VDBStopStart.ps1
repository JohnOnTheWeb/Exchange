 param (
    [object]$WebhookData
)

$Conn = Get-AutomationConnection -Name AzureRunAsConnection
Add-AzureRMAccount -ServicePrincipal -Tenant $Conn.TenantID -ApplicationId $Conn.ApplicationID -CertificateThumbprint $Conn.CertificateThumbprint

$rg = 'AZEUS2-DNA-AFT06'
$vms = @(@{Name="AZAFTVDB01";State="off"})

if ($WebhookData -ne $null)
{
    if ($WebhookData.RequestBody -ne $null)
    {
        $vms = ConvertFrom-Json -InputObject $WebhookData.RequestBody
        write-output "Read $($vms.Length) from request"
    }
    if ($WebhookData.RequestHeader -ne $null)
    {
        $rg = $WebhookData.RequestHeader.ResourceGroup
    }
}

$rg

$vms | % {
    $_.Name
    if ($_.Name -Match "AFTVDB")
    {
        $vm = Get-AzureRmVM -ResourceGroupName $rg -Status | Where Name -Match ($_.Name + "$")
        $vmState = $vm[0].PowerState
        $vmName = $vm[0].Name
        if ($vmState -eq "VM running")
        {
            $_.Name + " is running"
            if ($_.State -eq "off")
            {
                "stopping $vmName"
                Stop-AzureRmVM -ResourceGroupName $rg -Name $vmName -Force
            }
        }
        else
        {
            $_.Name + " is not running"
            if ($_.State -eq "on")
            {
                "starting $vmName"
                Start-AzureRmVM -ResourceGroupName $rg -Name $vmName
            }
        }
    }
}



