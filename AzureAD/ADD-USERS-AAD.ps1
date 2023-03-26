###################
#ADD-USERS-AAD.ps1#
###################

<#
.SYNOPSIS Añade usuarios a un grupo AAD

.DESCRIPTION Incluye los usuarios a un grupo en Azure AD


.NOTES 
FileName : ADD-USERS-AAD.ps.ps1
Author   : Borja Terres
Version  : 1.0
Date     : 11-noviembre-2022
Update   : 
Requires : PowerShell 5.1 or PowerShell 7.1.x (Core)
Module   : AzureAD
OS       : Windows




#>

#Elimina el comentario si te hace falta instalar el modulo de powershell 
#Import-Module AzureAD

#Conecta AzureAD
Connect-AzureAD
$block = @"
                         _             _
 _ __   _ __  __      __(_) _ __    __| |  ___  __      __ ___
| '_ \ | '_ \ \ \ /\ / /| || '_ \  / _  | / _ \ \ \ /\ / // __|
| | | || | | | \ V  V / | || | | || (_| || (_) | \ V  V / \__ \
|_| |_||_| |_|  \_/\_/  |_||_| |_| \__,_| \___/   \_/\_/  |___/





"@

Clear-Host
Write-Host $block -ForegroundColor Red


#Importamos los usuarios --> Indicamos la ruta donde vamos a poner el .csv   
$Users = Import-Csv C:\Scripts\INPUT\usuarios.csv

#Grupo al que queremos añadir usuarios    
$Group = "Excluidos-SecurityE3"
 
 
#Loop para añadir usuarios al grupo   
 foreach($user in $Users) {
     $AzureADUser = Get-AzureADUser -Filter "UserPrincipalName eq '$($user.UPN)'"
     if($AzureADUser -ne $null) {
         $AzureADGroup = Get-AzureADGroup -Filter "DisplayName eq '$Group'" -ErrorAction Stop
         $isUserMemberOfGroup = Get-AzureADGroupMember -ObjectId $AzureADGroup.ObjectId -All $true | Where-Object {$_.UserPrincipalName -like "*$($AzureADUser.UserPrincipalName)*"}
         if($isUserMemberOfGroup -eq $null) {
            Write-Host "Añadiendo usuario $user.upn al grupo $Group" -ForegroundColor Yellow
            Add-AzureADGroupMember -ObjectId $AzureADGroup.ObjectId -RefObjectId $AzureADUser.ObjectId -ErrorAction Stop
            }
     }
     else {
         Write-Output "El usuario no existe $user.upn" -foregroundColor red 
         Write-Output "El usuario no existe $user.upn" > C:\scripts\Output\ADD-USERS-ADD-Error.txt

     }


 }
