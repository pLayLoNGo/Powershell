#Sacar usuarios por fecha de expiración de contraseña
$ruta ='archivo.csv'

#Fecha
$fecha = "21/04/2021 08:00:00AM"

#Obtiene usuarios de un grupo, cuya fecha de cambio de contraseña es inferior. Pasar el CN del grupo.
get-aduser -Filter "(passwordlastset -lt '$fecha')" -SearchBase "OU=,OU=,DC=,DC=" -Properties UserPrincipalName, passwordlastset, passwordneverexpires |select-object UserPrincipalName,passwordlastset, passwordneverexpires | sort passwordlastset | ft UserPrincipalName,passwordlastset,passwordneverexpires > $ruta
