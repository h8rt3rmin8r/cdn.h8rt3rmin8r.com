<#
.SYNOPSIS
    Creates a desktop shortcut that opens the Windows Environment Variables dialog with Administrator privileges.

.DESCRIPTION
    This script generates a shortcut named "Edit Environment Variables" on the current user's Desktop. 
    The shortcut is configured to bypass the standard System Properties tabs and open the Environment Variables dialog directly.
    It includes a "RunAs" verb to ensure the dialog opens with elevated privileges, allowing modification of System variables.
    
    The shortcut uses a native Windows system icon (imageres.dll) for a professional appearance.

.PARAMETER Help
    Displays this help documentation and exits.

.EXAMPLE
    .\Install-EnvVarShortcut.ps1
    
    Generates the shortcut on the desktop immediately.

.EXAMPLE
    .\Install-EnvVarShortcut.ps1 -Help
    
    Displays the help text you are reading right now.

.NOTES
    Author: h8rt3rmin8r
    Date: 2025-12-10
    Platform: Windows 10/11
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory=$false)]
    [switch]$Help
)

# Logic to handle the -Help parameter
if ($Help) {
    # Check if the script is running from a file to retrieve the path
    if ($PSCommandPath) {
        Get-Help $PSCommandPath -Full
    } else {
        Write-Warning "Script is not running from a saved file. displaying generic help."
        Get-Help $MyInvocation.MyCommand.Name -Full
    }
    # Exit the script without running the installation logic
    return
}

# --- Main Script Logic Begins Here ---

# Configuration
$ShortcutName = "Edit Environment Variables"
# This points to a standard Windows icon that looks like a settings list/cog
$IconLocation = "$env:SystemRoot\system32\imageres.dll,78" 

try {
    # 1. Determine the path to the current user's Desktop
    $DesktopPath = [Environment]::GetFolderPath("Desktop")
    $ShortcutFile = Join-Path -Path $DesktopPath -ChildPath "$ShortcutName.lnk"

    # 2. Create the WScript Shell object to interact with shortcuts
    $WScriptShell = New-Object -ComObject WScript.Shell
    $Shortcut = $WScriptShell.CreateShortcut($ShortcutFile)

    # 3. Configure the shortcut target and arguments
    # Target: powershell.exe
    # Arguments: 
    #   -WindowStyle Hidden: Prevents a PowerShell window from flashing on screen
    #   -Command: The command to elevate and open the dialog
    $Shortcut.TargetPath = "powershell.exe"
    $Shortcut.Arguments = "-WindowStyle Hidden -Command ""Start-Process rundll32.exe -ArgumentList 'sysdm.cpl,EditEnvironmentVariables' -Verb RunAs"""
    
    # 4. Set the Icon and Description
    $Shortcut.IconLocation = $IconLocation
    $Shortcut.Description = "Opens System Environment Variables with Admin privileges"
    
    # 5. Save the shortcut to the Desktop
    $Shortcut.Save()

    Write-Host "SUCCESS: Shortcut '$ShortcutName' has been created on your Desktop." -ForegroundColor Green
}
catch {
    Write-Error "ERROR: Could not create shortcut. Details: $_"
}

# Optional: Pause so the user can see the success message if they double-clicked the script
if ($Host.Name -eq "ConsoleHost") {
    Read-Host "Press Enter to exit..."
}
