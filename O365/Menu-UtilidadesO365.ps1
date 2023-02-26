$Titulo1 = "Conjunto de scripts para realizar funciones habituales de Office365 y Exchange Online versión 1.2"
$GroupName = ""
$AllowGroupCreation = "True"

#Funcion conexión office365
function FConexion365
{
Import-Module MsOnline
Connect-MsolService
}

#Función que obtiene todos los usuarios de 365 con licencia y el tipo.
function FUsuariosOffice365
{
$licensedUsers = Get-MsolUser -All | Where-Object {$_.islicensed}
foreach ($user in $licensedUsers) {
        Write-Host "$($user.displayname)" -ForegroundColor Yellow  
        $licenses = $user.Licenses
        $licenseArray = $licenses | foreach-Object {$_.AccountSkuId}
        $licenseString = $licenseArray -join ", "
        Write-Host "$($user.displayname) tiene $licenseString" -ForegroundColor Green
        $licensedProperties = [pscustomobject][ordered]@{
            DisplayName       = $user.DisplayName
            Licenses          = $licenseString
            UserPrincipalName = $user.UserPrincipalName
        }
        $licensedProperties | Export-CSV  $home\documents\Usuarios365_$(Get-Date -format dd_MM_yyyy).csv -Encoding utf8 -Append -NoTypeInformation -WarningAction SilentlyContinue 
    }
}

<#Funcion que obtiene los usuarios que tienen licencia Kiosko
function FUsuariosKiosko
{
Get-MsolUser | Where-Object {($_.licenses).AccountSkuId -match "EXCHANGEDESKLESS"} |fl DisplayName > $home\documents\usuarioskiosko_$(Get-Date -format dd_MM_yyyy).csv
Get-MsolUser | Where-Object {($_.licenses).AccountSkuId -match "EXCHANGEDESKLESS"} |fl DisplayName,UserPrincipalName
Write-Host "`n"
Write-Host -foregroundcolor Black -backgroundcolor Yellow "Se ha creado un archivo dentro de tus documentos con el nombre usuarioskiosko_$(Get-Date -format dd_MM_yyyy).csv"
}

#Funcion que obtiene los usuarios que tienen licencia Plan1
function FUsuariosPlan
{
Get-MsolUser | Where-Object {($_.licenses).AccountSkuId -match "EXCHANGESTANDARD"} |fl DisplayName,UserPrincipalName > $home\documents\usuariosplan1_$(Get-Date -format dd_MM_yyyy).csv
Get-MsolUser | Where-Object {($_.licenses).AccountSkuId -match "EXCHANGESTANDARD"} |fl DisplayName,UserPrincipalName
Write-Host "`n"
Write-Host -foregroundcolor Black -backgroundcolor Yellow "Se ha creado un archivo dentro de tus documentos con el nombre usuariosplan1_$(Get-Date -format dd_MM_yyyy).csv"
}
#>

#Funcion que conecta al Exchange Online
function FConexionExchange
{
$UserCredential = Get-Credential
$Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/ -Credential $UserCredential -Authentication Basic -AllowRedirection
Import-PSSession $Session -DisableNameChecking
Write-Host -foregroundcolor Black -backgroundcolor Yellow "Acuérdate de desconectarte de Exchange antes de salir."
}

#Funcion que modifica los buzones para que puedan recibir citas en el calendario
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

#Funcion que obtiene el tamaño de los buzones
function FTamBuzones
{
Write-Host "Obteniendo los tamaños de todos los buzones."
$MailBox = Get-Mailbox -ResultSize Unlimited
$MailBox | %{Get-MailboxStatistics -Identity $_.UserPrincipalName | Select DisplayName,@{name="TotalItemSize (MB)";expression={[math]::Round(([double]$_.TotalItemSize.ToString().Split("(")[1].Split(" ")[0].Replace(",","")/1MB),2)}},@{name="TotalDeletedItemSize (MB)";expression={[math]::Round(($_.TotalDeletedItemSize.ToString().Split("(")[1].Split(" ")[0].Replace(",","")/1MB),2)}},ItemCount,DeletedItemCount,LastLogoffTime,LastLogonTime} | Export-Csv $home\documents\Buzones_$(Get-Date -format dd_MM_yyyy).csv -Encoding utf8 -NoTypeInformation -Delimiter ";" -WarningAction SilentlyContinue 
Write-Host "`n"
Write-Host -foregroundcolor Black -backgroundcolor Yellow "Se ha creado un archivo dentro de tus documentos con el nombre Buzones_$(Get-Date -format dd_MM_yyyy).csv"
}

#Funcion para ver y modificar la directiva de retención de los buzones. Solo los modifica con la directiva Kiosko
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

#Funcion para ver en que buzones está activa la autenticacion multifactor
function FMFAActivado
{
Get-MsolUser -All | where {$_.StrongAuthenticationMethods -ne $null} | Select-Object -Property UserPrincipalName | Sort-Object userprincipalname | Tee-Object $home\documents\UsuariosMFA_$(Get-Date -format dd_MM_yyyy).csv
Write-Host "`n"
Write-Host -foregroundcolor Black -backgroundcolor Yellow "Se ha creado un archivo dentro de tus documentos con el nombre UsuariosMFA_$(Get-Date -format dd_MM_yyyy).csv"
}

#Funcion para ver en que buzones no está activa la autenticacion multifactor
function FMFASinActivar
{
Get-MsolUser -All | where {$_.StrongAuthenticationMethods.Count -eq 0} | Select-Object -Property UserPrincipalName | Sort-Object userprincipalname | Tee-Object $home\documents\UsuariosSinMFA_$(Get-Date -format dd_MM_yyyy).csv
#Get-MsolUser -All | where {$_.StrongAuthenticationMethods.Count -eq 0} | Select-Object -Property UserPrincipalName | Sort-Object userprincipalname > $home\documents\UsuariosSinMFA_$(Get-Date -format dd_MM_yyyy).csv
Write-Host "`n"
Write-Host -foregroundcolor Black -backgroundcolor Yellow "Se ha creado un archivo dentro de tus documentos con el nombre UsuariosSinMFA_$(Get-Date -format dd_MM_yyyy).csv"
}

#Funcion para ver que usuarios no se han logado en los últimos 90 días
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

#Funcion para ver las reglas de reenvio creadas en los buzones
function FReglasFW
{
$mailboxes=Get-mailbox -resultsize Unlimited
$rules = $mailboxes | foreach { get-inboxRule –mailbox $_.alias }
$rules | where { ( $_.forwardAsAttachmentTo –ne $NULL ) –or ( $_.forwardTo –ne $NULL ) –or ( $_.redirectTo –ne $NULL ) } | ft name,identity,ruleidentity > $home\documents\Reglas.csv
Write-Host "`n"
Write-Host -foregroundcolor Black -backgroundcolor Yellow "Se ha creado un archivo dentro de tus documentos con el nombre Reglas.csv"
}


#Funcion para conectarte al servicio Azure AD
function FConexionAzure
{
#Conecta con el Preview, ya que permite más funciones
AzureADPreview\Connect-AzureAD
}


#Bloquea la creación de grupos en Office365 por parte de los usuarios excepto TI
function FGrupos365Ti
{
$GroupName = "ti"
$AllowGroupCreation = "False"

$settingsObjectID = (Get-AzureADDirectorySetting | Where-object -Property Displayname -Value "Group.Unified" -EQ).id
if(!$settingsObjectID)
{
      $template = Get-AzureADDirectorySettingTemplate | Where-object {$_.displayname -eq "group.unified"}
    $settingsCopy = $template.CreateDirectorySetting()
    New-AzureADDirectorySetting -DirectorySetting $settingsCopy
    $settingsObjectID = (Get-AzureADDirectorySetting | Where-object -Property Displayname -Value "Group.Unified" -EQ).id
}

$settingsCopy = Get-AzureADDirectorySetting -Id $settingsObjectID
$settingsCopy["EnableGroupCreation"] = $AllowGroupCreation

if($GroupName)
{
    $settingsCopy["GroupCreationAllowedGroupId"] = (Get-AzureADGroup -SearchString $GroupName).objectid
}
 else {
$settingsCopy["GroupCreationAllowedGroupId"] = $GroupName
}
Set-AzureADDirectorySetting -Id $settingsObjectID -DirectorySetting $settingsCopy

(Get-AzureADDirectorySetting -Id $settingsObjectID).Values
}

#Permite la creación de grupos en Office365 por parte de los usuarios
function FGrupos365Usu
{
$GroupName = ""
$AllowGroupCreation = "True"

$settingsObjectID = (Get-AzureADDirectorySetting | Where-object -Property Displayname -Value "Group.Unified" -EQ).id
if(!$settingsObjectID)
{
      $template = Get-AzureADDirectorySettingTemplate | Where-object {$_.displayname -eq "group.unified"}
    $settingsCopy = $template.CreateDirectorySetting()
    New-AzureADDirectorySetting -DirectorySetting $settingsCopy
    $settingsObjectID = (Get-AzureADDirectorySetting | Where-object -Property Displayname -Value "Group.Unified" -EQ).id
}

$settingsCopy = Get-AzureADDirectorySetting -Id $settingsObjectID
$settingsCopy["EnableGroupCreation"] = $AllowGroupCreation

if($GroupName)
{
    $settingsCopy["GroupCreationAllowedGroupId"] = (Get-AzureADGroup -SearchString $GroupName).objectid
}
 else {
$settingsCopy["GroupCreationAllowedGroupId"] = $GroupName
}
Set-AzureADDirectorySetting -Id $settingsObjectID -DirectorySetting $settingsCopy

(Get-AzureADDirectorySetting -Id $settingsObjectID).Values
}




# Funciones Directorio Activo Local

function FConexionAD
{
Import-module ActiveDirectory
}

# Deshabilita la cuenta de usuario y le quita de todos los grupos.
function FDeshabilitarAcc
{
Clear-Host
$Cuenta = Read-Host "Introduce el nombre de la cuenta que quieres deshabilitar, (x ej. xxx@fhecor.es o xxx)"
if ($Cuenta) {
try{
	Get-ADUser -Identity $Cuenta
	$Grupos = Get-ADPrincipalGroupMembership -Identity $Cuenta | where {$_.Name -ne "Domain Users"}
	if ($Grupos -ne $null){
		Remove-ADPrincipalGroupMembership -Identity $Cuenta -MemberOf $Grupos  -Confirm:$false
	}
}
catch{
	Write-Host "$Cuenta no está en el Directorio Activo"
}
Disable-ADAccount -Identity $Cuenta
} else
{Write-Warning -Message "Error, no has introducido la cuenta"
}

Write-Host "`n"
Write-Host -ForegroundColor DarkCyan "`nLa cuenta $Cuenta está deshabilitada y sacada de todos los grupos."

}

# Listado de cuentas y cuando caduca su contraseña
function FCaducidadAcc
{
Get-ADUser -filter {Enabled -eq $True -and PasswordNeverExpires -eq $False} –Properties "DisplayName", "msDS-UserPasswordExpiryTimeComputed" | Select-Object -Property "Displayname",@{Name="ExpiryDate";Expression={[datetime]::FromFileTime($_."msDS-UserPasswordExpiryTimeComputed")}}
}


# Listado de cuentas cuya contraseña no caduca
function FNoCaducidadAcc
{
get-Aduser -filter {Enabled -eq $True -and PasswordNeverExpires -eq $True} –Properties "DisplayName" | select-object DisplayName | Sort-Object Name | ConvertTo-Csv -NoTypeInformation | % {$_.Replace('"','')} | Out-File $home\documents\No_caduca.csv
}

# Saca un listado con los usuarios y su extensión
function FAgenda
{
Get-ADUser -filter * -Properties DisplayName, OfficePhone | where {$_.enabled -eq $true -and $_.OfficePhone -ne $null} | Select-Object Name,OfficePhone | Sort-Object Name | ConvertTo-Csv -NoTypeInformation | % {$_.Replace('"','')} | Out-File $home\documents\Agenda1.csv
import-Csv $home\documents\agenda1.csv | ForEach-Object {
	New-Object PSObject -Property ([Ordered] @{
	"Name" = $_.Name
	"OfficePhone" = $_.OfficePhone
	"Presence" = ",1" -f $_.Name
	"Directory" = ",0" -f $_.Name
	})
} | Export-Csv -Encoding unicode $home\documents\Agenda.csv -NoTypeInformation -Delimiter "," -WarningAction SilentlyContinue
Remove-item -Path $home\documents\Agenda1.csv
Write-Warning -Message "Se ha creado un archivo en tus documentos con el nombre de agenda.csv"
}

# Obtiene la fecha del último login de los usuarios deshabilitados
function FUltimoLogin
{
Get-ADUser -Filter {Enabled -eq $False} -Properties “LastLogonDate” |sort-object -Property "LastLogonDate" | select-object Name,LastLogonDate | Tee-Object $home\documents\UsuariosDeshabilitados_$(Get-Date -format dd_MM_yyyy).csv
Write-Host "Se ha creado un archivo en tus documentos con el nombre de UsuariosDeshabilitados_$(Get-Date -format dd_MM_yyyy).csv"

}



# Utilidades
#Funcion para la instalación de modulos de PowerShell
function FInstModulos
{
Write-Warning -Message "Se va a proceder a instalar los módulos de PowerShell necesarios."
# Actualización del 20 de abril del 2020 para la configuración de TLS 1.2

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 
Install-Module PowerShellGet -RequiredVersion 2.2.4 -SkipPublisherCheck

#Instalación del módulo Office365
Install-Module -Name MSOnline -Force

#Instalación del módulo Exchange Online
Install-Module -Name ExchangeOnlineManagement -Force


#Instalación de los modulos de Azure
Install-module AzureADPreview -Force
Install-Module AzureAD -Force

}

# Función de actualización de modulos
function FActModulos
{
Write-Warning -Message "Se va a proceder a actualizar todos los módulos de PowerShell instalados."
Update-Module -Force -AcceptLicense
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
		Write-Host -ForegroundColor DarkCyan -NoNewline "`n["; Write-Host -NoNewline "3"; Write-Host -ForegroundColor DarkCyan -NoNewline "]"; `
            Write-Host -ForegroundColor DarkCyan " Funciones Azure Online"
		Write-Host -ForegroundColor DarkCyan -NoNewline "`n["; Write-Host -NoNewline "4"; Write-Host -ForegroundColor DarkCyan -NoNewline "]"; `
            Write-Host -ForegroundColor DarkCyan " Funciones Directorio Activo Local"
		Write-Host -ForegroundColor DarkCyan -NoNewline "`n["; Write-Host -NoNewline "5"; Write-Host -ForegroundColor DarkCyan -NoNewline "]"; `
            Write-Host -ForegroundColor DarkCyan " Utilidades"
        $MenuPrincipal = Read-Host "`nElige una opción (en blanco para salir)"
        
        # Inicia el subMenu Office365
        if($MenuPrincipal -eq 1){
            subMenuO365
        }
		# Inicia el subMenu Exchange Online
		if($MenuPrincipal -eq 2){
            subMenuExOn
        }
		# Inicia el subMenu Azure
		if($MenuPrincipal -eq 3){
            subMenuAzOn
        }
		# Inicia el subMenu AD local
		if($MenuPrincipal -eq 4){
            subMenuAD
        }
		# Inicia el subMenu utilidades
		if($MenuPrincipal -eq 5){
            subMenuUtil
        }
    }
}



function subMenuO365 {
    $subMenuO365 = 'X'
    while($subMenuO365 -ne ''){
        Clear-Host
        Write-Host "`n$Titulo1 `n"
        Write-Host -ForegroundColor Cyan "Funciones Office365"
        Write-Host -ForegroundColor DarkCyan -NoNewline "`n["; Write-Host -NoNewline "1"; Write-Host -ForegroundColor DarkCyan -NoNewline "]"; `
            Write-Host -ForegroundColor DarkCyan " Conexión Office365"
        Write-Host -ForegroundColor DarkCyan -NoNewline "`n["; Write-Host -NoNewline "2"; Write-Host -ForegroundColor DarkCyan -NoNewline "]"; `
            Write-Host -ForegroundColor DarkCyan " Obtener usuarios del Office365 y su licencia"
		Write-Host -ForegroundColor DarkCyan -NoNewline "`n["; Write-Host -NoNewline "3"; Write-Host -ForegroundColor DarkCyan -NoNewline "]"; `
            Write-Host -ForegroundColor DarkCyan " Obtener usuarios con MFA activado"
		Write-Host -ForegroundColor DarkCyan -NoNewline "`n["; Write-Host -NoNewline "4"; Write-Host -ForegroundColor DarkCyan -NoNewline "]"; `
            Write-Host -ForegroundColor DarkCyan " Obtener usuarios sin MFA activado"
		Write-Host -ForegroundColor DarkCyan -NoNewline "`n["; Write-Host -NoNewline "5"; Write-Host -ForegroundColor DarkCyan -NoNewline "]"; `
            Write-Host -ForegroundColor DarkCyan " Obtener usuarios sin loguearse en 90 días"
        $subMenuO365 = Read-Host "`nElige una opción (en blanco para volver al menu principal)"
        $timeStamp = Get-Date -Uformat %m%d%y%H%M
        # Opción 1
        if($subMenuO365 -eq 1){
            FConexion365
            Write-Host -ForegroundColor DarkCyan "`nScript de conexión ejecutado."
            Write-Host "`nPulsa cualquier tecla para volver al menu anterior"
            [void][System.Console]::ReadKey($true)
        }
        # Opción 2
        if($subMenuO365 -eq 2){
            FUsuariosOffice365
            Write-Host -ForegroundColor DarkCyan "`nScript de usuarios de Office365 ejecutado."
            Write-Host "`nPulsa cualquier tecla para volver al menu anterior"
            [void][System.Console]::ReadKey($true)
		}
		
		if($subMenuO365 -eq 3){
            FMFAActivado
            Write-Host -ForegroundColor DarkCyan "`nScript de usuarios con MFA activado ejecutado."
            Write-Host "`nPulsa cualquier tecla para volver al menu anterior"
            [void][System.Console]::ReadKey($true)
        }
		if($subMenuO365 -eq 4){
            FMFASinActivar
            Write-Host -ForegroundColor DarkCyan "`nScript de usuarios sin MFA activado ejecutado."
            Write-Host "`nPulsa cualquier tecla para volver al menu anterior"
            [void][System.Console]::ReadKey($true)
        }
		if($subMenuO365 -eq 5){
            FLogUsuarios
            Write-Host -ForegroundColor DarkCyan "`nScript de usuarios sin logarse 90 días ejecutado."
            Write-Host "`nPulsa cualquier tecla para volver al menu anterior"
            [void][System.Console]::ReadKey($true)
        }
		
    }
}

function subMenuExOn {
    $subMenuExOn = 'X'
    while($subMenuExOn -ne ''){
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
        $subMenuExOn = Read-Host "`nElige una opción (en blanco para volver al menu principal)"
        
        if($subMenuExOn -eq 1){
            FConexionExchange
            Write-Host -ForegroundColor DarkCyan "`nConexión a Exchange Online completado."
            Write-Host "`nPulsa cualquier tecla para volver al menu anterior"
            [void][System.Console]::ReadKey($true)
        }
        
        if($subMenuExOn -eq 2){
			FCalendario
            Write-Host -ForegroundColor DarkCyan "`nUsuario cambiado."
            Write-Host "`nPulsa cualquier tecla para volver al menu anterior"
            [void][System.Console]::ReadKey($true)
        }
		if($subMenuExOn -eq 3){
            FTamBuzones
            Write-Host -ForegroundColor DarkCyan "`nScript de tamaño de buzones ejecutado."
            Write-Host "`nPulsa cualquier tecla para volver al menu anterior"
            [void][System.Console]::ReadKey($true)
        }
		if($subMenuExOn -eq 4){
			FKiosko
            #Get-DistributionGroupMember -Identity "Kiosk_secgrp365" |select Name,RetentionPolicy
            Write-Host -ForegroundColor DarkCyan "`nScript de tamaño de buzones ejecutado."
            Write-Host "`nPulsa cualquier tecla para volver al menu anterior"
            [void][System.Console]::ReadKey($true)
        }
		if($subMenuExOn -eq 5){
			FReglasFW
            Write-Host -ForegroundColor DarkCyan "`nScript de obtención de reglas ejecutado."
            Write-Host "`nPulsa cualquier tecla para volver al menu anterior"
            [void][System.Console]::ReadKey($true)
        }
		if($subMenuExOn -eq 6){
            Get-PSSession | Remove-PSSession
            Write-Host -ForegroundColor DarkCyan "`nCerrada la conexión con Exchange Online."
            Write-Host "`nPulsa cualquier tecla para volver al menu anterior"
            [void][System.Console]::ReadKey($true)
        }
    }
}


function subMenuAzOn {
	$subMenuReq = 'X'
	while($subMenuAzOn -ne ''){
		Clear-Host
		Write-Host "`n$Titulo1 `n"
		Write-Host -ForegroundColor Cyan "Funciones Azure Online"
        Write-Host -ForegroundColor DarkCyan -NoNewline "`n["; Write-Host -NoNewline "1"; Write-Host -ForegroundColor DarkCyan -NoNewline "]"; `
        Write-Host -ForegroundColor DarkCyan " Conexión Azure Online"
		Write-Host -ForegroundColor DarkCyan -NoNewline "`n["; Write-Host -NoNewline "2"; Write-Host -ForegroundColor DarkCyan -NoNewline "]"; `
        Write-Host -ForegroundColor DarkCyan " Habilitar a los usuarios la creación de equipos en Office365"	
		Write-Host -ForegroundColor DarkCyan -NoNewline "`n["; Write-Host -NoNewline "3"; Write-Host -ForegroundColor DarkCyan -NoNewline "]"; `
        Write-Host -ForegroundColor DarkCyan " Deshabilitar a los usuarios la creación de equipos en Office365"	
		$subMenuAzOn = Read-Host "`nElige una opción (en blanco para volver al menu principal)"
		
		if($subMenuAzOn -eq 1){
            FConexionAzure
            Write-Host -ForegroundColor DarkCyan "`nConexión a Azure Online completado."
            Write-Host "`nPulsa cualquier tecla para volver al menu anterior"
            [void][System.Console]::ReadKey($true)
        }
        if($subMenuAzOn -eq 2){
            FGrupos365Usu
            Write-Host -ForegroundColor DarkCyan "`nPermitido a los usuarios la creación de equipos en Office365."
            Write-Host "`nPulsa cualquier tecla para volver al menu anterior"
            [void][System.Console]::ReadKey($true)
        }
		if($subMenuAzOn -eq 3){
            $GroupName = "ti"
			FGrupos365TI
            Write-Host -ForegroundColor DarkCyan "`nDeshabilitada la creación de equipos en Office365 por parte de usuarios."
            Write-Host "`nPulsa cualquier tecla para volver al menu anterior"
            [void][System.Console]::ReadKey($true)
        }
		}
}

function subMenuAD {
	$subMenuReq = 'X'
	while($subMenuAD -ne ''){
		Clear-Host
		Write-Host "`n$Titulo1 `n"
		Write-Host -ForegroundColor Cyan "Funciones Directorio Activo Local"
		Write-Host -ForegroundColor DarkCyan -NoNewline "`n["; Write-Host -NoNewline "1"; Write-Host -ForegroundColor DarkCyan -NoNewline "]"; `
        Write-Host -ForegroundColor DarkCyan " Conexión Directorio Activo local"
        Write-Host -ForegroundColor DarkCyan -NoNewline "`n["; Write-Host -NoNewline "2"; Write-Host -ForegroundColor DarkCyan -NoNewline "]"; `
        Write-Host -ForegroundColor DarkCyan " Suspensión cuenta"
		Write-Host -ForegroundColor DarkCyan -NoNewline "`n["; Write-Host -NoNewline "3"; Write-Host -ForegroundColor DarkCyan -NoNewline "]"; `
        Write-Host -ForegroundColor DarkCyan " Fecha de caducidad de contraseñas"	
		Write-Host -ForegroundColor DarkCyan -NoNewline "`n["; Write-Host -NoNewline "4"; Write-Host -ForegroundColor DarkCyan -NoNewline "]"; `
        Write-Host -ForegroundColor DarkCyan " Listado de cuentas que no caducan"	
		Write-Host -ForegroundColor DarkCyan -NoNewline "`n["; Write-Host -NoNewline "5"; Write-Host -ForegroundColor DarkCyan -NoNewline "]"; `
        Write-Host -ForegroundColor DarkCyan " Creación agenda teléfonos"	
		Write-Host -ForegroundColor DarkCyan -NoNewline "`n["; Write-Host -NoNewline "6"; Write-Host -ForegroundColor DarkCyan -NoNewline "]"; `
        Write-Host -ForegroundColor DarkCyan " Listado de usuarios deshabilitados y fecha del último login"	
		$subMenuAD = Read-Host "`nElige una opción (en blanco para volver al menu principal)"
		if($subMenuAD -eq 1){
			FConexionAD
			Write-Host -ForegroundColor DarkCyan "`nIniciado el módulo de Directorio Activo."
            Write-Host "`nPulsa cualquier tecla para volver al menu anterior"
            [void][System.Console]::ReadKey($true)
		}
		if($subMenuAD -eq 2){
			FDeshabilitarAcc
			#Write-Host -ForegroundColor DarkCyan "`nCuenta deshabilitada."
            Write-Host "`nPulsa cualquier tecla para volver al menu anterior"
            [void][System.Console]::ReadKey($true)
		}
		if($subMenuAD -eq 3){
			FCaducidadAcc
			Write-Host -ForegroundColor DarkCyan "`nTerminado el listado."
            Write-Host "`nPulsa cualquier tecla para volver al menu anterior"
            [void][System.Console]::ReadKey($true)
		}
		if($subMenuAD -eq 4){
			FNoCaducidadAcc
			Write-Host -ForegroundColor DarkCyan "`nListado de cuentas que no caducan terminado."
            Write-Host "`nPulsa cualquier tecla para volver al menu anterior"
            [void][System.Console]::ReadKey($true)
		}
		if($subMenuAD -eq 5){
			FAgenda
			Write-Host -ForegroundColor DarkCyan "`nCreación de listado de usuarios y sus teléfonos terminado."
            Write-Host "`nPulsa cualquier tecla para volver al menu anterior"
            [void][System.Console]::ReadKey($true)
		}
		if($subMenuAD -eq 6){
			FUltimoLogin
			Write-Host -ForegroundColor DarkCyan "`nListado terminado."
            Write-Host "`nPulsa cualquier tecla para volver al menu anterior"
            [void][System.Console]::ReadKey($true)
		}
	}
}










function subMenuUtil {
	$subMenuReq = 'X'
	while($subMenuUtil -ne ''){
		Clear-Host
		Write-Host "`n$Titulo1 `n"
		Write-Host -ForegroundColor Cyan "Utilidades"
		Write-Host -ForegroundColor DarkCyan -NoNewline "`n["; Write-Host -NoNewline "1"; Write-Host -ForegroundColor DarkCyan -NoNewline "]"; `
        Write-Host -ForegroundColor DarkCyan " Instalación de los módulos de PowerShell necesarios."
        Write-Host -ForegroundColor DarkCyan -NoNewline "`n["; Write-Host -NoNewline "2"; Write-Host -ForegroundColor DarkCyan -NoNewline "]"; `
        Write-Host -ForegroundColor DarkCyan " Actualización de los módulos de PowerShell instalados."
		$subMenuUtil = Read-Host "`nElige una opción (en blanco para volver al menu principal)"
		if($subMenuUtil -eq 1){
			FInstModulos
			Write-Host -ForegroundColor DarkCyan "`nInstalación de módulos PS completado."
            Write-Host "`nPulsa cualquier tecla para volver al menu anterior"
            [void][System.Console]::ReadKey($true)
		}
		if($subMenuUtil -eq 2){
			FActModulos
			Write-Host -ForegroundColor DarkCyan "`nActualización de módulos PS completado."
            Write-Host "`nPulsa cualquier tecla para volver al menu anterior"
            [void][System.Console]::ReadKey($true)
		}
	}
}

MenuPrincipal