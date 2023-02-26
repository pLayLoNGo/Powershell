#Ruta para exportar 
$ruta = ''

Get-ADGroupMember -Identity "PSO_USUARIOS" -Recursive | Get-ADUser -Property DisplayName | Select-Object DisplayName | Sort-Object DisplayName | export-csv -Encoding UTF8 $ruta