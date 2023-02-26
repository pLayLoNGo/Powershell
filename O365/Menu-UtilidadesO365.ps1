$Titulo1 = "Conjunto de scripts para realizar funciones habituales de Office365 y Exchange Online versión 1.0"
function FConexion365
{
	
Install-Module -Name MSOnline
Import-Module MsOnline
Connect-MsolService

}

function FUsuariosKiosko
{
Get-MsolUser | Where-Object {($_.licenses).AccountSkuId -match "EXCHANGEDESKLESS"} |fl DisplayName,UserPrincipalName > $home\documents\usuarioskiosko_$(Get-Date -format dd_MM_yyyy).csv
Get-MsolUser | Where-Object {($_.licenses).AccountSkuId -match "EXCHANGEDESKLESS"} |fl DisplayName,UserPrincipalName
Write-Host "`n"
Write-Host -foregroundcolor Black -backgroundcolor Yellow "Se ha creado un archivo dentro de tus documentos con el nombre usuarioskiosko_$(Get-Date -format dd_MM_yyyy).csv"
}

function FUsuariosPlan
{
Get-MsolUser | Where-Object {($_.licenses).AccountSkuId -match "EXCHANGESTANDARD"} |fl DisplayName,UserPrincipalName > $home\documents\usuariosplan1_$(Get-Date -format dd_MM_yyyy).csv
Get-MsolUser | Where-Object {($_.licenses).AccountSkuId -match "EXCHANGESTANDARD"} |fl DisplayName,UserPrincipalName
Write-Host "`n"
Write-Host -foregroundcolor Black -backgroundcolor Yellow "Se ha creado un archivo dentro de tus documentos con el nombre usuariosplan1_$(Get-Date -format dd_MM_yyyy).csv"
}

function FConexionExchange
{
$UserCredential = Get-Credential
$Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/ -Credential $UserCredential -Authentication Basic -AllowRedirection
Import-PSSession $Session -DisableNameChecking
Write-Host -foregroundcolor Black -backgroundcolor Yellow "Acuérdate de desconectarte de Exchange antes de salir."
}

function FCalendario
{
Clear-Host
$Buzon = Read-Host "Introduce el nombre del buzon, (x ej. xxx@fhecor.es o xxx)"
if ($Buzon) {
Set-CasMailbox $Buzon -ImapUseProtocolDefaults $false -PopUseProtocolDefaults $false -ImapForceIcalForCalendarRetrievalOption $true -PopForceICalForCalendarRetrievalOption $true
} else
{Write-Warning -Message "Error, no has introducido el buzon"
}

Write-Host "`n"

Write-Host "Hecho. El buzon" $Buzon "ha sido modificado para la recepcion de citas en el calendario"

}

function FTamBuzones
{
Write-Host "Obteniendo los tamaños de todos los buzones."
$MailBox = Get-Mailbox -ResultSize Unlimited
$MailBox | %{Get-MailboxStatistics -Identity $_.UserPrincipalName | Select DisplayName,@{name="TotalItemSize (MB)";expression={[math]::Round(([double]$_.TotalItemSize.ToString().Split("(")[1].Split(" ")[0].Replace(",","")/1MB),2)}},@{name="TotalDeletedItemSize (MB)";expression={[math]::Round(($_.TotalDeletedItemSize.ToString().Split("(")[1].Split(" ")[0].Replace(",","")/1MB),2)}},ItemCount,DeletedItemCount,LastLogoffTime,LastLogonTime} | Export-Csv $home\documents\Buzones_$(Get-Date -format dd_MM_yyyy).csv -Encoding utf8 -NoTypeInformation -Delimiter ";" -WarningAction SilentlyContinue 
Write-Host "`n"
Write-Host -foregroundcolor Black -backgroundcolor Yellow "Se ha creado un archivo dentro de tus documentos con el nombre Buzones_$(Get-Date -format dd_MM_yyyy).csv"
}

function FKiosko
{
Get-DistributionGroupMember -Identity "Kiosk_secgrp365" |select Name,RetentionPolicy
Get-DistributionGroupMember -Identity "Kiosk_secgrp365" |select Name,RetentionPolicy > $home\documents\kiosk_secgrp365_$(Get-Date -format dd_MM_yyyy).csv
Write-Host -foregroundcolor Black -backgroundcolor Yellow "Se ha creado un archivo dentro de tus documentos con el nombre kiosk_secgrp365_$(Get-Date -format dd_MM_yyyy).csv"
$Retention = Read-Host "`n¿Deseas asignar a la directiva de retención Kiosko a todos los miembros del grupo? (s/n)"
	if ($Retention -eq 's'){
		Get-DistributionGroupMember -Identity "Kiosk_secgrp365" |set-mailbox -retentionPolicy "Kiosko"
		}
	if ($Retention -ne 's'){
			[void][System.Console]::ReadKey($true)
		}
}

function FMFAActivado
{
Get-MsolUser -All | where {$_.StrongAuthenticationMethods -ne $null} | Select-Object -Property UserPrincipalName | Sort-Object userprincipalname 
}

function FMFASinActivar
{
Get-MsolUser -All | where {$_.StrongAuthenticationMethods.Count -eq 0} | Select-Object -Property UserPrincipalName | Sort-Object userprincipalname
Get-MsolUser -All | where {$_.StrongAuthenticationMethods.Count -eq 0} | Select-Object -Property UserPrincipalName | Sort-Object userprincipalname > $home\documents\UsuariosSinMFA_$(Get-Date -format dd_MM_yyyy).csv
Write-Host "`n"
Write-Host -foregroundcolor Black -backgroundcolor Yellow "Se ha creado un archivo dentro de tus documentos con el nombre UsuariosSinMFA_$(Get-Date -format dd_MM_yyyy).csv"
}

function FLogUsuarios
{
$startDate = (Get-Date).AddDays(-90).ToString('MM/dd/yyyy')
$endDate = (Get-Date).ToString('MM/dd/yyyy')

$allUsers = @()
$allUsers = Get-MsolUser -All -EnabledFilter EnabledOnly | Select UserPrincipalName

$loggedOnUsers = @()
$loggedOnUsers = Search-UnifiedAuditLog -StartDate $startDate -EndDate $endDate -Operations UserLoggedIn, PasswordLogonInitialAuthUsingPassword, UserLoginFailed -ResultSize 5000

$inactiveInLastThreeMonthsUsers = @()
$inactiveInLastThreeMonthsUsers = $allUsers.UserPrincipalName | where {$loggedOnUsers.UserIds -NotContains $_}

Write-Output "Los siguientes usuarios no se han logueados en los últimos 90 días:"
Write-Output $inactiveInLastThreeMonthsUsers

}

function FReglasFW
{
$mailboxes=Get-mailbox -resultsize Unlimited
$rules = $mailboxes | foreach { get-inboxRule –mailbox $_.alias }
$rules | where { ( $_.forwardAsAttachmentTo –ne $NULL ) –or ( $_.forwardTo –ne $NULL ) –or ( $_.redirectTo –ne $NULL ) } | ft name,identity,ruleidentity > $home\documents\Reglas.csv
Write-Host "`n"
Write-Host -foregroundcolor Black -backgroundcolor Yellow "Se ha creado un archivo dentro de tus documentos con el nombre Reglas.csv"
}


function MenuPrincipal 
{
    $MenuPrincipal = 'X'
    while($MenuPrincipal -ne ''){
        Clear-Host
        Write-Host "`n$Titulo1 `n"
        Write-Host -ForegroundColor Cyan "Menu Principal"
        Write-Host -ForegroundColor DarkCyan -NoNewline "`n["; Write-Host -NoNewline "1"; Write-Host -ForegroundColor DarkCyan -NoNewline "]"; `
            Write-Host -ForegroundColor DarkCyan " Funciones Office365"
        Write-Host -ForegroundColor DarkCyan -NoNewline "`n["; Write-Host -NoNewline "2"; Write-Host -ForegroundColor DarkCyan -NoNewline "]"; `
            Write-Host -ForegroundColor DarkCyan " Funciones Exchange Online"
        $MenuPrincipal = Read-Host "`nElige una opción (en blanco para salir)"
        # Inicia el subMenu1
        if($MenuPrincipal -eq 1){
            subMenu1
        }
        # Inicia el subMenu2
        if($MenuPrincipal -eq 2){
            subMenu2
        }
    }
}


function subMenu1 {
    $subMenu1 = 'X'
    while($subMenu1 -ne ''){
        Clear-Host
        Write-Host "`n$Titulo1 `n"
        Write-Host -ForegroundColor Cyan "Funciones Office365"
        Write-Host -ForegroundColor DarkCyan -NoNewline "`n["; Write-Host -NoNewline "1"; Write-Host -ForegroundColor DarkCyan -NoNewline "]"; `
            Write-Host -ForegroundColor DarkCyan " Conexión Office365"
        Write-Host -ForegroundColor DarkCyan -NoNewline "`n["; Write-Host -NoNewline "2"; Write-Host -ForegroundColor DarkCyan -NoNewline "]"; `
            Write-Host -ForegroundColor DarkCyan " Obtener usuarios con licencia kiosko"
		Write-Host -ForegroundColor DarkCyan -NoNewline "`n["; Write-Host -NoNewline "3"; Write-Host -ForegroundColor DarkCyan -NoNewline "]"; `
            Write-Host -ForegroundColor DarkCyan " Obtener usuarios con licencia plan1"
		Write-Host -ForegroundColor DarkCyan -NoNewline "`n["; Write-Host -NoNewline "4"; Write-Host -ForegroundColor DarkCyan -NoNewline "]"; `
            Write-Host -ForegroundColor DarkCyan " Obtener usuarios con MFA activado"
		Write-Host -ForegroundColor DarkCyan -NoNewline "`n["; Write-Host -NoNewline "5"; Write-Host -ForegroundColor DarkCyan -NoNewline "]"; `
            Write-Host -ForegroundColor DarkCyan " Obtener usuarios sin MFA activado"
		Write-Host -ForegroundColor DarkCyan -NoNewline "`n["; Write-Host -NoNewline "6"; Write-Host -ForegroundColor DarkCyan -NoNewline "]"; `
            Write-Host -ForegroundColor DarkCyan " Obtener usuarios sin loguearse en 90 días"
        $subMenu1 = Read-Host "`nElige una opción (en blanco para volver al menu principal)"
        $timeStamp = Get-Date -Uformat %m%d%y%H%M
        # Opción 1
        if($subMenu1 -eq 1){
            FConexion365
            Write-Host -ForegroundColor DarkCyan "`nScript de conexión ejecutado."
            Write-Host "`nPulsa cualquier tecla para volver al menu anterior"
            [void][System.Console]::ReadKey($true)
        }
        # Opción 2
        if($subMenu1 -eq 2){
            FUsuariosKiosko
            Write-Host -ForegroundColor DarkCyan "`nScript de usuarios de kiosko ejecutado."
            Write-Host "`nPulsa cualquier tecla para volver al menu anterior"
            [void][System.Console]::ReadKey($true)
		#Opción 3	
        }
		if($subMenu1 -eq 3){
            FUsuariosPlan
            Write-Host -ForegroundColor DarkCyan "`nScript de usuarios de plan1 ejecutado."
            Write-Host "`nPulsa cualquier tecla para volver al menu anterior"
            [void][System.Console]::ReadKey($true)
        }
		if($subMenu1 -eq 4){
            FMFAActivado
            Write-Host -ForegroundColor DarkCyan "`nScript de usuarios con MFA activado ejecutado."
            Write-Host "`nPulsa cualquier tecla para volver al menu anterior"
            [void][System.Console]::ReadKey($true)
        }
		if($subMenu1 -eq 5){
            FMFASinActivar
            Write-Host -ForegroundColor DarkCyan "`nScript de usuarios sin MFA activado ejecutado."
            Write-Host "`nPulsa cualquier tecla para volver al menu anterior"
            [void][System.Console]::ReadKey($true)
        }
		if($subMenu1 -eq 6){
            FLogUsuarios
            Write-Host -ForegroundColor DarkCyan "`nScript de usuarios sin logarse 90 días ejecutado."
            Write-Host "`nPulsa cualquier tecla para volver al menu anterior"
            [void][System.Console]::ReadKey($true)
        }
		
    }
}

function subMenu2 {
    $subMenu2 = 'X'
    while($subMenu2 -ne ''){
        Clear-Host
        Write-Host "`n$Titulo1 `n"
        Write-Host -ForegroundColor Cyan "Funciones Exchange Online"
        Write-Host -ForegroundColor DarkCyan -NoNewline "`n["; Write-Host -NoNewline "1"; Write-Host -ForegroundColor DarkCyan -NoNewline "]"; `
            Write-Host -ForegroundColor DarkCyan " Conexión Exchange Online"
        Write-Host -ForegroundColor DarkCyan -NoNewline "`n["; Write-Host -NoNewline "2"; Write-Host -ForegroundColor DarkCyan -NoNewline "]"; `
            Write-Host -ForegroundColor DarkCyan " Modificar un buzón para la recepción de citas de calendario"
		Write-Host -ForegroundColor DarkCyan -NoNewline "`n["; Write-Host -NoNewline "3"; Write-Host -ForegroundColor DarkCyan -NoNewline "]"; `
            Write-Host -ForegroundColor DarkCyan " Obtener el tamaño de todos los buzones"
		Write-Host -ForegroundColor DarkCyan -NoNewline "`n["; Write-Host -NoNewline "4"; Write-Host -ForegroundColor DarkCyan -NoNewline "]"; `
            Write-Host -ForegroundColor DarkCyan " Obtener los usuarios del grupo Kiosk_secgrp365 y su directiva de retención"
		Write-Host -ForegroundColor DarkCyan -NoNewline "`n["; Write-Host -NoNewline "5"; Write-Host -ForegroundColor DarkCyan -NoNewline "]"; `
            Write-Host -ForegroundColor DarkCyan " Obtiene todas las reglas y comprueba si son reenviadores"
		Write-Host -ForegroundColor DarkCyan -NoNewline "`n["; Write-Host -NoNewline "6"; Write-Host -ForegroundColor DarkCyan -NoNewline "]"; `
            Write-Host -ForegroundColor DarkCyan " Desconexión de Exchange Online"
        $subMenu2 = Read-Host "`nElige una opción (en blanco para volver al menu principal)"
        
        if($subMenu2 -eq 1){
            FConexionExchange
            Write-Host -ForegroundColor DarkCyan "`nConexión a Exchange Online completado."
            Write-Host "`nPulsa cualquier tecla para volver al menu anterior"
            [void][System.Console]::ReadKey($true)
        }
        
        if($subMenu2 -eq 2){
			FCalendario
            Write-Host -ForegroundColor DarkCyan "`nUsuario cambiado."
            Write-Host "`nPulsa cualquier tecla para volver al menu anterior"
            [void][System.Console]::ReadKey($true)
        }
		if($subMenu2 -eq 3){
            FTamBuzones
            Write-Host -ForegroundColor DarkCyan "`nScript de tamaño de buzones ejecutado."
            Write-Host "`nPulsa cualquier tecla para volver al menu anterior"
            [void][System.Console]::ReadKey($true)
        }
		if($subMenu2 -eq 4){
			FKiosko
            #Get-DistributionGroupMember -Identity "Kiosk_secgrp365" |select Name,RetentionPolicy
            Write-Host -ForegroundColor DarkCyan "`nScript de tamaño de buzones ejecutado."
            Write-Host "`nPulsa cualquier tecla para volver al menu anterior"
            [void][System.Console]::ReadKey($true)
        }
		if($subMenu2 -eq 5){
			FReglasFW
            Write-Host -ForegroundColor DarkCyan "`nScript de obtención de reglas ejecutado."
            Write-Host "`nPulsa cualquier tecla para volver al menu anterior"
            [void][System.Console]::ReadKey($true)
        }
		if($subMenu2 -eq 6){
            Get-PSSession | Remove-PSSession
            Write-Host -ForegroundColor DarkCyan "`nCerrada la conexión con Exchange Online."
            Write-Host "`nPulsa cualquier tecla para volver al menu anterior"
            [void][System.Console]::ReadKey($true)
        }
    }
}

MenuPrincipal