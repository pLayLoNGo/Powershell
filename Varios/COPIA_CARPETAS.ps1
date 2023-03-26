<#
.SYNOPSIS Copia masiva de carpetas

.DESCRIPTION Copia todos los archivos de una carpeta a multiples servidores

.NOTES File Name : COPIA_CARPETAS.ps1
Author   : Borja Terres
Version  : 1.0
Date     : 24-junio-2022
Update   : 
Requires : PowerShell 5.1 or PowerShell 7.1.x (Core)
Module   : 
OS       : Windows
 

.EXAMPLE
.\COPIA_CARPETAS.ps1 -CarpetaOrigen [Ubicación de la carpeta] -CarpetaDestino [Donde lo copiamos] -FicheroServidores [Ubicación del fichero servidores] -Verbose
Indicamos la carpeta de origen, la ruta donde queremos que se copie (si no existe la crea) y le pasamos un fichero con los nombres de los servidores
 a donde queremos que se copie.
#>

[CmdletBinding()]
Param (
    [Parameter(Position = 0, Mandatory = $true, HelpMessage = 'Carpeta de origen')]
    [Alias('CarpetaOrigen')]
    [String]$CarpetaOrigen,

    [Parameter(Position = 1, Mandatory = $True, HelpMessage = 'Carpeta de destino')]
    [Alias('CarpetaDestino')]
    [String]$CarpetaDestino,

    [Parameter(Position = 2, Mandatory = $true, HelpMessage = 'Ubicación del fichero de servidores')]
    [Alias('FicheroServidores')]
    [String]$FicheroServidores

)

$Servidores = Get-Content $FicheroServidores
foreach ($Servidor in $Servidores
    {
    $ExisteCarpeta = Test-Path -Path $CarpetaDestino
    if ($ExisteCarpeta -eq $false)
        {
        New-item -Path \\$Servidor\$CarpetaDestino -ItemType Directory
        }
        copy-item $CarpetaOrigen -Destination \\$Servidor\$CarpetaDestino -Recurse
        Write-Host "Copiado a " "$Servidor"
    }

