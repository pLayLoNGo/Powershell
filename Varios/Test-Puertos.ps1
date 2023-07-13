$servers = Get-Content -Path C:\test_puertos.txt
$puertos   =  "3389"
foreach ($server in $servers) {

    #BUSCA EN CADA SERVIDOR y si lo encuentra lo añade al servidor.
    $TestPuertos = Test-NetConnection $server -Port $puertos -WarningAction SilentlyContinue
    If ($TestPuertos.tcpTestSucceeded -eq $false)
    {
        Write-Host $server $puertos -Separator " => " -ForegroundColor Red 
        $server+","+ $TestPuertos.RemoteAddress.IPAddressToString | Out-file -FilePath C:\Scripts\output\error3389.txt -Append

    }

}
