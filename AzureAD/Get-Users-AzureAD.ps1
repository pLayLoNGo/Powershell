# Ruta donde guarda los usuarios
$csv = "C:\temp\grp365.txt"

# Get Credentials to connect
$Credential = Get-Credential
   
# Create the session
$Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/ `
           -Credential $Credential -Authentication Basic -AllowRedirection
   
# Import the session
Import-PSSession $Session -DisableNameChecking
 
# Get all Members of Office 365 Group
Get-UnifiedGroup -Identity "direccion@correo.com" | Get-UnifiedGroupLinks -LinkType Member > $csv
  
# Remove the session
Remove-PSSession $Session