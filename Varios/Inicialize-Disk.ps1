$Disk = Get-Disk |where operationalstatus -eq 'Offline'

foreach ($HDD in $Disk)
    {
    
    get-disk $HDD.Number | Initialize-Disk -PartitionStyle GPT -PassThru |

    New-Partition -AssignDriveLetter -UseMaximumSize |

    Format-Volume -FileSystem NTFS -NewFileSystemLabel “Datos $HDD.number” -Confirm:$false 

}
