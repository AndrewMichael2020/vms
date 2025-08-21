# Windows Startup Script for VMS Data Science Workstation
# This script runs during Windows Sysprep and configures the VM

# Enable Windows Defender
Set-MpPreference -DisableRealtimeMonitoring $false
Update-MpSignature

# Format and mount the data disk as D:
$disk = Get-Disk | Where-Object { $_.PartitionStyle -eq 'RAW' -and $_.Size -gt 10GB } | Select-Object -First 1
if ($disk) {
    Initialize-Disk -Number $disk.Number -PartitionStyle MBR
    New-Partition -DiskNumber $disk.Number -UseMaximumSize -DriveLetter D | Format-Volume -FileSystem NTFS -NewFileSystemLabel "DataDisk" -Confirm:$false
    Write-Host "Data disk mounted as D:"
}

# Create desktop shortcut for Power BI download
$WshShell = New-Object -comObject WScript.Shell
$Shortcut = $WshShell.CreateShortcut("$Home\Desktop\Download Power BI.url")
$Shortcut.TargetPath = "https://powerbi.microsoft.com/desktop"
$Shortcut.Save()

# Enable automatic updates
$AutoUpdate = (New-Object -ComObject Microsoft.Update.AutoUpdate).Settings
$AutoUpdate.NotificationLevel = 4  # Download and install automatically
$AutoUpdate.Save()

# Set timezone to UTC (can be changed by user)
Set-TimeZone -Id "UTC"

# Create a welcome message
$WelcomeMessage = @"
Welcome to your VMS Data Science Workstation!

This VM has been configured with:
- Windows Server 2022
- Data disk mounted as D: drive
- Windows Defender enabled and updated
- Automatic Windows updates enabled
- Network access restricted to your IP address

Next steps:
1. Download and install Power BI Desktop from the desktop shortcut
2. Use the D: drive for your data storage
3. Configure any additional software you need

For support, refer to the VMS documentation.
"@

$WelcomeMessage | Out-File -FilePath "$Home\Desktop\Welcome.txt" -Encoding UTF8

Write-Host "VMS Windows startup configuration completed successfully!"