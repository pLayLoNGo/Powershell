Crear grupo de seguridad, añadir a los usuarios y pasar el siguiente script.
#https://docs.microsoft.com/es-es/microsoft-365/solutions/manage-creation-of-groups?view=o365-worldwide
#si queremos permitir la creación de grupos
#cambiar $GroupName en "" y $AllowGroupCreation en "True" y vuelva a ejecutar el script.
#NOMBRE DEL GRUPO
$GroupName = "Creación_Equipos"
$AllowGroupCreation = $False
 
Connect-AzureAD
 
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
