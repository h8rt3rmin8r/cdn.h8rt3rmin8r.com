<#
.SYNOPSIS
    Launches a Chrome window to view a specified file, directory, or URL.
.DESCRIPTION
    This script launches a Chrome window to view a specified file, directory, or
    Internet URL. Additional inputs can be provided to customize the size and
    position of the window.
.PARAMETER Interactive
    If set, the script will prompt the user to select a file, directory, or URL
    using a graphical interface. This parameter is mutually exclusive with the
    Target parameter (which specifies the target directly).
    Alias: i
.PARAMETER Target
    The target file, directory, or URL to be opened in Chrome. This parameter is
    mutually exclusive with the Interactive parameter (which uses an interface
    to select the target).
    Aliases: t, f, d, p, path, file, directory
.PARAMETER PositionX
    The X position of the Chrome window on the screen in pixels.
    Alias: px, x, windowpositionx
    Default: 100
.PARAMETER PositionY
    The Y position of the Chrome window on the screen in pixels.
    Alias: py, y, windowpositiony
    Default: 100
.PARAMETER WindowHeight
    The height of the Chrome window in pixels.
    Alias: wh, height
    Default: 800
.PARAMETER WindowWidth
    The width of the Chrome window in pixels.
    Alias: ww, width
    Default: 1200
.PARAMETER Verbosity
    If set to $true, the script will output verbose messages.
    Alias: v
    Default: $false
.PARAMETER Help
    Display the script help information.
    Alias: h
.EXAMPLE
    ChromeWindowLauncher.ps1 -Target "C:\Users\JohnDoe\Documents" -Verbosity $true
    Launches a Chrome window to view the specified directory with verbose output.
#>
[CmdletBinding(SupportsShouldProcess=$true,ConfirmImpact='None',DefaultParameterSetName='Default')]
Param(
    [Parameter(Mandatory=$true,ParameterSetName='RunChromeInteractive')]
    [Alias("i")]
    [Switch]$Interactive,

    [Parameter(Mandatory=$true,Position=0,ParameterSetName='RunChrome')]
    [Alias("t","f","d","p","path","file","directory")]
    [System.String]$Target,

    [Parameter(Mandatory=$false,ParameterSetName='RunChrome')]
    [Parameter(Mandatory=$false,ParameterSetName='RunChromeInteractive')]
    [Alias("px","x","windowpositionx")]
    [System.Int32]$PositionX = 100,

    [Parameter(Mandatory=$false,ParameterSetName='RunChrome')]
    [Parameter(Mandatory=$false,ParameterSetName='RunChromeInteractive')]
    [Alias("py","y","windowpositiony")]
    [System.Int32]$PositionY = 100,

    [Parameter(Mandatory=$false,ParameterSetName='RunChrome')]
    [Parameter(Mandatory=$false,ParameterSetName='RunChromeInteractive')]
    [Alias("wh","height")]
    [System.Int32]$WindowHeight = 800,

    [Parameter(Mandatory=$false,ParameterSetName='RunChrome')]
    [Parameter(Mandatory=$false,ParameterSetName='RunChromeInteractive')]
    [Alias("ww","width")]
    [System.Int32]$WindowWidth = 1200,

    [Parameter(Mandatory=$false,ParameterSetName='HelpText')]
    [Parameter(Mandatory=$false,ParameterSetName='RunChrome')]
    [Parameter(Mandatory=$false,ParameterSetName='RunChromeInteractive')]
    [Alias("v")]
    [System.Boolean]$Verbosity = $false,

    [Parameter(Mandatory=$true,ParameterSetName='HelpText')]
    [Alias("h")]
    [Switch]$Help
)
#______________________________________________________________________________
## Declare Functions

    function Detect-TargetType {
        <#
        .SYNOPSIS
            Detect the type of target (file, directory, or URL).
        .DESCRIPTION
            This function detects the type of target (file, directory, or URL) based on
            the provided input. It returns a string indicating the type of target.

            Outputs "file", "directory", "url", or "null" if the target is invalid.
        #>
        Param(
            [System.String]$Target = $Target,
            [System.Boolean]$Verbosity = $Verbosity
        )
        $thisSubFunction = "{0}" -f $MyInvocation.MyCommand
        $thisFunction = if ($null -eq $thisFunction) { $thisSubFunction } else { -join("$thisFunction", ":", "$thisSubFunction") }
        if (-Not($Target)) {
            Vbs -Caller "$thisFunction" -Status e -Message "The target is null or empty." -Verbosity $Verbosity
            return "null"
        }
        if (Test-Path -LiteralPath "$Target" -PathType Leaf) {
            Vbs -Caller "$thisFunction" -Status i -Message "Detected target as file: $Target" -Verbosity $Verbosity
            return "file"
        } elseif (Test-Path -LiteralPath "$Target" -PathType Container) {
            Vbs -Caller "$thisFunction" -Status i -Message "Detected target as directory: $Target" -Verbosity $Verbosity
            return "directory"
        } elseif ($Target -match '^(https?|ftps?|sftp|file|mailto|chrome|s3):\/\/') {
            Vbs -Caller "$thisFunction" -Status i -Message "Detected target as URL: $Target" -Verbosity $Verbosity
            return "url"
        } else {
            Vbs -Caller "$thisFunction" -Status e -Message "The target '$Target' is invalid. (Returning a 'null' string)" -Verbosity $Verbosity
            return "null"
        }
    }

    function Format-TargetString {
        <#
        .SYNOPSIS
            Alternative target string formatting for Chrome window sizing workaround
        .DESCRIPTION
            This function formats the target string for the Chrome window sizing workaround.
            It returns a formatted string that can be used in the Chrome command line.
        .NOTES
            This workaround may not always work. For more information, read this
            StackOverflow post: https://stackoverflow.com/a/71146261/8672154
        .PARAMETER PositionX
            The X position of the Chrome window on the screen in pixels.
        .PARAMETER PositionY
            The Y position of the Chrome window on the screen in pixels.
        .PARAMETER WindowHeight
            The height of the Chrome window in pixels.
        .PARAMETER WindowWidth
            The width of the Chrome window in pixels.
        .PARAMETER Target
            The target file, directory, or URL to be opened in Chrome.
        .PARAMETER TargetType
            The type of target (file, directory, or URL) to be formatted.
        .PARAMETER Verbosity
            If set to $true, the function will print verbose messages.
        .EXAMPLE
            Format-TargetString -PositionX 100 -PositionY 100 -WindowHeight 800 -WindowWidth 1200 -Target "C:\Users\JohnDoe\Documents" -TargetType "file" -Verbosity $true
            Returns a formatted target string for the specified file and prints a message to the console.
        #>
        Param(
            [Parameter(Mandatory=$false)]
            [int32]$PositionX = $PositionX,

            [Parameter(Mandatory=$false)]
            [int32]$PositionY = $PositionY,

            [Parameter(Mandatory=$false)]
            [int32]$WindowHeight = $WindowHeight,

            [Parameter(Mandatory=$false)]
            [int32]$WindowWidth = $WindowWidth,

            [Parameter(Mandatory=$false)]
            [System.String]$Target = $Target,

            [Parameter(Mandatory=$false)]
            [ValidateSet("url","file","directory")]
            [System.String]$TargetType = $TargetType,

            [Parameter(Mandatory=$false)]
            [Switch]$NoPrefix,

            [Parameter(Mandatory=$false)]
            [System.Boolean]$Verbosity = $Verbosity
        )
        $thisSubFunction = "{0}" -f $MyInvocation.MyCommand
        $thisFunction = if ($null -eq $thisFunction) { $thisSubFunction } else { -join("$thisFunction", ":", "$thisSubFunction") }
        $output = $null
        $FormattedTarget = $null
        Switch ($TargetType) {
            "file" {
                $Target = (Get-Item -LiteralPath "$Target").FullName
                $Target = $Target -replace '\\', '/'
                $Target = $Target -replace ' ', '%20'
                $FormattedTarget = $Target
                Vbs -Caller "$thisFunction" -Status i -Message "Formatted target string for file: $FormattedTarget" -Verbosity $Verbosity
            }
            "directory" {
                $Target = (Get-Item -LiteralPath "$Target").FullName
                $Target = $Target -replace '\\', '/'
                $Target = $Target -replace ' ', '%20'
                $FormattedTarget = $Target
                Vbs -Caller "$thisFunction" -Status i -Message "Formatted target string for directory: $FormattedTarget" -Verbosity $Verbosity
            }
            "url" {
                $Target = $Target -replace ' ', '%20'
                if ($Target -notmatch '^(https?|ftps?|sftp|file|mailto|chrome|s3):\/\/') {
                    # If the URL target does not have a transfer protocol on it, then add "http://"
                    $FormattedTarget = -join("http://","$Target")
                } else {
                    # The URL target has a transfer protocol on it, so just use it as is
                    $FormattedTarget = $Target
                }
                Vbs -Caller "$thisFunction" -Status i -Message "Formatted target string for URL: $FormattedTarget" -Verbosity $Verbosity
            }
        }
        if ($null -eq $FormattedTarget) {
            Vbs -Caller "$thisFunction" -Status e -Message "Failed to format target string for target type: $TargetType" -Verbosity $Verbosity
            return $output
        }
        # If the target type is a URL, implement the workaround. Otherwise, prefix the
        # target with "file:///" and return the formatted target string.
        if ($TargetType -eq "url") {
            # Construct the workaround string. This method uses Javascript injection to
            # forcibly resize the window since (for some unknown reason) Chrome ignores
            # it's own "--window-size" and "--window-position" command line arguments.
            $TargetSegment_A = "data:text/html,<script>window.moveTo("
            $TargetSegment_B = "$PositionX"
            $TargetSegment_C = ","
            $TargetSegment_D = "$PositionY"
            $TargetSegment_E = ");window.resizeTo("
            $TargetSegment_F = "$WindowWidth"
            $TargetSegment_G = ","
            $TargetSegment_H = "$WindowHeight"
            $TargetSegment_I = ");window.location='"
            $TargetSegment_J = "$FormattedTarget"
            $TargetSegment_K = "';</script>"
            $PreOutput = -join("$TargetSegment_A","$TargetSegment_B","$TargetSegment_C","$TargetSegment_D","$TargetSegment_E","$TargetSegment_F","$TargetSegment_G","$TargetSegment_H","$TargetSegment_I","$TargetSegment_J","$TargetSegment_K")
        } else {
            $PreOutput = -join("file:///","$FormattedTarget")
        }
        # Handle the NoPrefix switch (used for testing purposes to determine various Chrome
        # window behaviors with and without the --app= prefix)
        if ($NoPrefix) {
            $output = -join('"',"$PreOutput",'"')
        } else {
            $output = -join("--app=",'"',"$PreOutput",'"')
        }
        # Write a verbosity logging message and return the final output string
        Vbs -Caller "$thisFunction" -Status d -Message "Formatted target string for workaround: $output" -Verbosity $Verbosity
        return $output
    }

    function Get-ChromeArgs {
        <#
        .SYNOPSIS
            Get the command line arguments for launching Chrome.
        .DESCRIPTION
            This function constructs an array of arguments for launching Chrome with the
            specified target, window size, and window position. It returns the arguments
            as an array of strings.
        .PARAMETER TargetString
            The formatted target string for the Chrome window.
        .PARAMETER PositionX
            The X position of the Chrome window on the screen in pixels.
        .PARAMETER PositionY
            The Y position of the Chrome window on the screen in pixels.
        .PARAMETER WindowHeight
            The height of the Chrome window in pixels.
        .PARAMETER WindowWidth
            The width of the Chrome window in pixels.
        .PARAMETER Verbosity
            If set to $true, the function will print verbose messages.
        #>
        Param(
            [Parameter(Mandatory=$true)]
            [System.String]$TargetString,

            [Parameter(Mandatory=$true)]
            [System.Int32]$PositionX,

            [Parameter(Mandatory=$true)]
            [System.Int32]$PositionY,

            [Parameter(Mandatory=$true)]
            [System.Int32]$WindowHeight,

            [Parameter(Mandatory=$true)]
            [System.Int32]$WindowWidth,

            [Parameter(Mandatory=$false)]
            [System.Boolean]$Verbosity = $Verbosity
        )
        $thisSubFunction = "{0}" -f $MyInvocation.MyCommand
        $thisFunction = if ($null -eq $thisFunction) { $thisSubFunction } else { -join("$thisFunction", ":", "$thisSubFunction") }
        $WindowPositionString = -join("$PositionX",",","$PositionY")
        $WindowSizeString = -join("$WindowWidth",",","$WindowHeight")
        $ChromeArgs = @(
            '--new-window',
            '--disable-infobars',
            '--disable-extensions',
            '--no-sandbox',
            '--profile-directory=Default',
            '--enable-features=FileHandlingAPI',
            "--window-position=$WindowPositionString",
            "--window-size=$WindowSizeString",
            "$TargetString"
        )
        Vbs -Caller "$thisFunction" -Status d -Message "Chrome arguments array constructed" -Verbosity $Verbosity
        return $ChromeArgs
    }

    function Get-ChromePath {
        <#
        .SYNOPSIS
            Get the path to the Chrome executable.
        .DESCRIPTION
            This function searches the common installation paths and returns the
            path to the Chrome executable (if found).
        .PARAMETER Verbosity
            If set to $true, the function will print verbose messages.
        .EXAMPLE
            Get-ChromePath -Verbosity $true
            Returns the path to the Chrome executable and prints a message to the console.
        #>
        Param(
            [System.Boolean]$Verbosity = $Verbosity
        )
        $thisSubFunction = "{0}" -f $MyInvocation.MyCommand
        $thisFunction = if ($null -eq $thisFunction) { $thisSubFunction } else { -join("$thisFunction", ":", "$thisSubFunction") }
        $output = $null
        $ChromeFound = $false
        $possiblePaths = @(
            "$env:ProgramFiles\Google\Chrome\Application\chrome.exe",
            "$env:ProgramFiles(x86)\Google\Chrome\Application\chrome.exe",
            "$env:LOCALAPPDATA\Google\Chrome\Application\chrome.exe"
        )
        foreach ($path in $possiblePaths) {
            # If ChromeFound is true, break out of the loop
            if ($ChromeFound) { break }
            # Check if the path exists and is a file
            if (Test-Path -LiteralPath $path -PathType Leaf) {
                Vbs -Caller "$thisFunction" -Status s -Message "Chrome found at: $path" -Verbosity $Verbosity
                $output = $path
                $ChromeFound = $true
            }
        }
        # If Chrome is not found, print an error message. Either way, return $output
        if (-Not($ChromeFound)) {
            Vbs -Caller "$thisFunction" -Status e -Message "Chrome not found in common installation paths." -Verbosity $Verbosity
        }
        return $output
    }

    function Launch-ChromeWindow {
        <#
        .SYNOPSIS
            Launch a Chrome window with the finalized internal arguments.
        .DESCRIPTION
            This function launches a Chrome window with the specified arguments.
            It is called after the arguments have been constructed and validated.

            If the target type is a file or directory, native Windows utilities are used
            to force-resize the window to the specified dimensions. This is because
            Chrome does not allow us to set the window position and size when using the
            '--app=' argument on a file or directory (as this violates the CORS policy
            of the browser).

            If the target type is a URL, the Chrome command line arguments are used to
            set the window size and position.
        .PARAMETER ChromeExe
            The path to the Chrome executable.
        .PARAMETER ChromeArgs
            The array of command line arguments for launching Chrome.
        .PARAMETER TargetType
            The type of target (file, directory, or URL) to be opened in Chrome.
        .PARAMETER PositionX
            The X position of the Chrome window on the screen in pixels.
        .PARAMETER PositionY
            The Y position of the Chrome window on the screen in pixels.
        .PARAMETER WindowHeight
            The height of the Chrome window in pixels.
        .PARAMETER WindowWidth
            The width of the Chrome window in pixels.
        .PARAMETER Verbosity
            If set to $true, the function will print verbose messages.
        #>
        Param(
            [Parameter(Mandatory=$true)]
            [System.String]$ChromeExe,

            [Parameter(Mandatory=$true)]
            [System.Array]$ChromeArgs,

            [Parameter(Mandatory=$true)]
            [ValidateSet("url","file","directory")]
            [System.String]$TargetType,

            [Parameter(Mandatory=$true)]
            [System.Int32]$PositionX,

            [Parameter(Mandatory=$true)]
            [System.Int32]$PositionY,

            [Parameter(Mandatory=$true)]
            [System.Int32]$WindowHeight,

            [Parameter(Mandatory=$true)]
            [System.Int32]$WindowWidth,

            [Parameter(Mandatory=$false)]
            [System.Boolean]$Verbosity = $Verbosity
        )
        $thisSubFunction = "{0}" -f $MyInvocation.MyCommand
        $thisFunction = if ($null -eq $thisFunction) { $thisSubFunction } else { -join("$thisFunction", ":", "$thisSubFunction") }
        ## If the TargetType is NOT 'url', then we need to intervene and force the newly
        ## created window to be positioned correctly. This is because Chrome does not
        ## allow us to set the window position and size when using the '--app=' argument
        ## on a file or directory (as this violates the CORS policy of the browser).
        ## We will use the SetWindowPos function from the user32.dll library to set the
        ## window position and size.
        # Use Start-Process to launch Chrome with the constructed arguments
        Vbs -Caller "$thisFunction" -Status i -Message "Launching Chrome ..." -Verbosity $Verbosity
        $chromeProcess = Start-Process -FilePath $ChromeExe -ArgumentList $ChromeArgs -PassThru -ErrorAction SilentlyContinue
        $chromeProcessId = $chromeProcess.Id
        # Log the process ID of the launched Chrome window
        Vbs -Caller "$thisFunction" -Status s -Message "Chrome activated with process ID: $chromeProcessId" -Verbosity $Verbosity
        # Begin the window positioning process if the target type is a file or directory
        if (($TargetType -eq 'file') -Or ($TargetType -eq 'directory')) {
            # Wait for the Chrome window to be ready and get its handle
            $timeout = 15 # seconds
            $startTime = Get-Date
            $windowHandle = $null # Initialize the window handle variable
            while (((Get-Date) -le $startTime.AddSeconds($timeout)) -and ($null -eq $windowHandle)) {
                Start-Sleep -Milliseconds 500
                # Get all Chrome processes (because we all know Chrome spawns like a million of them)
                $chromeProcesses = Get-Process -ProcessName "chrome" -ErrorAction SilentlyContinue
                foreach ($process in $chromeProcesses) {
                    try {
                        $process.Refresh() # Refresh process information
                        if ($process.MainWindowHandle -ne 0) { # Check if the window handle is valid
                            $windowHandle = $process.MainWindowHandle
                            break
                        }
                    } catch {
                        Vbs -Caller "$thisFunction" -Status w -Message "Error refreshing process or retrieving window handle." -Verbosity $Verbosity
                    }
                }
            }
            # Use the SetWindowPos function to set the window position and size
            if ($windowHandle) {
                # Check if the type 'WindowAPI.NativeMethods' already exists
                # It may already exist if this function has been called before in the
                # same Powershell session. If it does, then we don't need to redefine it.
                if (-not ([System.Management.Automation.PSTypeName]'WindowAPI.NativeMethods').Type) {
                    # Define the SetWindowPos function signature using a Here-String for clarity and correctness
                    $signature = @"
[DllImport("user32.dll", SetLastError = true)]
[return: MarshalAs(UnmanagedType.Bool)]
public static extern bool SetWindowPos(IntPtr hWnd, IntPtr hWndInsertAfter, int X, int Y, int cx, int cy, uint uFlags);

public static readonly IntPtr HWND_TOP = (IntPtr)0;
public static readonly IntPtr HWND_NOTOPMOST = (IntPtr)(-2);
public static readonly uint SWP_NOSIZE = 0x0001;
public static readonly uint SWP_NOZORDER = 0x0004;
"@
                    Add-Type -Name "NativeMethods" -Namespace "WindowAPI" -MemberDefinition $signature
                }
                # Set the window position and size using the SetWindowPos function
                $windowPosition = [WindowAPI.NativeMethods]::SetWindowPos(
                    $windowHandle, [WindowAPI.NativeMethods]::HWND_TOP,
                    $PositionX, $PositionY, $WindowWidth, $WindowHeight,
                    [WindowAPI.NativeMethods]::SWP_NOZORDER
                )
                if (-not $windowPosition) {
                    Vbs -Caller "$thisFunction" -Status w -Message "Failed to set window position using SetWindowPos." -Verbosity $Verbosity
                } else {
                    Vbs -Caller "$thisFunction" -Status s -Message "Chrome window positioned successfully." -Verbosity $Verbosity
                }
            } else {
                Vbs -Caller "$thisFunction" -Status w -Message "Could not retrieve Chrome window handle." -Verbosity $Verbosity
            }
        }
        return
    }

    function Vbs {
        <#
        .SYNOPSIS
            Print structured and colorized verbosity and write formatted log messages
        .DESCRIPTION
            Print structured and colorized verbosity and write formatted log messages.
            This function is designed to be used as a logging function for other library
            functions and scripts. Care has been taken to ensure the portability of this
            function so it can be easily implemented in other scripts and functions
            unrelated to this library.
        .PARAMETER Message
            The message to be printed to the console and written to the log file.
        .PARAMETER Caller
            The name of the calling function or script. If the function is a sub-function,
            then the name of the parent function should be included.
            Syntax: "<Script>:<Function>:<Sub-Function>"
        .PARAMETER Status
            The status of the message
            Allowed Values: INFO (i), ERROR (e), WARNING (w), DEBUG (d)
            Default: INFO (i)
        .PARAMETER LogDir
            The directory in which the log file will be written. Normally this shouldn't be
            changed.
        .PARAMETER LibName
            The name of the library or script that is calling this function. This is used to
            identify the source of the log message. Normally this shouldn't be changed.
        .PARAMETER VbsSessionID
            The unique identifier for the current session. This is used to identify the
            session in which the log message was generated. Normally this shouldn't be
            changed.
        .PARAMETER Verbosity
            If set to $true, the message will be printed to the console and written to the
            log file. If set to $false, the message will be written to the log file only.
            Default: $true
        .EXAMPLE
            Vbs -Caller "$thisFunction" -Status info -Message "This is a test" -Verbosity $true
        #>
        Param(
            [System.String]$Message,

            [System.String]$Caller,

            [System.String]$Status,

            [Alias("LogDirectory")]
            [System.String]$LogDir = $D_ScriptData_Logs,

            [Alias("LibraryName")]
            [System.String]$LibName = $ThisScriptBaseName,

            [System.String]$VbsSessionID = $SessionToken,

            [Alias("v")]
            [System.Boolean]$Verbosity
        )

        function VbsFunctionStackTotalDepth {
            # Calculate the total depth of the updated function stack
            # Each non-numbered function is counted as 1 and each numbered function is
            # counted as the number in the numeric suffix.
            Param(
                [System.String]$CurrentStack
            )
            # Trim whitespace and colon characters from the end of the stack string
            $CurrentStack = $CurrentStack -replace "[:\s]+$", ""
            # Split the current stack into an array
            $CurrentStackArray = $CurrentStack -split ':'
            # Initialize a variable to hold the total depth of the stack
            $TotalDepth = [int]0
            foreach ($function in $CurrentStackArray) {
                if ($function -match '\d+') {
                    # If a numeric suffix is found, then increment the total depth by the numeric suffix
                    $TotalDepth += [int]$matches[0]
                } else {
                    # If no numeric suffix is found, then increment the total depth by 1
                    $TotalDepth += [int]1
                }
            }
            return $TotalDepth
        }

        function VbsLogPath {
            # Derive the path to the current log file based on the current date
            Param(
                [System.String]$LibName = $LibName,
                [System.String]$LogDir = $LogDir
            )
            $LogName = (Get-Date -UFormat "%Y%m")
            $LogFile = -join("$LibName","-","$LogName", ".log")
            $LogPath = -join("$LogDir", '\', "$LogFile")
            return $LogPath
        }

        function VbsLogRealityCheck {
            # Check if the log directory and log file exist. If they don't, then create them.
            Param(
                [System.String]$LogPath,
                [System.String]$LogDir = "$LogDir"
            )
            $DCheck = (Test-Path -LiteralPath "$LogDir" -PathType Container)
            $FCheck = (Test-Path -LiteralPath "$LogPath" -PathType Leaf)
            if ($DCheck -eq $false) {New-Item -ItemType Directory -Path "$LogDir" -Force > $null}
            if ($FCheck -eq $false) {New-Item -ItemType File -Path "$LogPath" -Force > $null}
            return
        }

        function VbsLogWrite {
            # Write the input string to the log file
            Param(
                [System.String]$LogPath,
                [System.String]$InputString
            )
            Add-Content -Path "$LogPath" -Value "$InputString"
            return
        }

        function VbsUpdateFunctionStack {
            param (
                [System.String]$CurrentStack,
                [System.String]$NewFunction
            )

            function VbsUpdateFunctionStackExtractNumber {
                # This sub-function discovers existing numeric suffixes in function names and returns only those
                # values which are meaningful to assist in incrementing the current cycle count as needed.
                Param(
                    [System.String]$String = $null
                )
                if ($String -match '\d+') {
                    $TempNumber = [int]$matches[0]
                    if ($TempNumber -lt 2) {
                        # If the numeric suffix is less than 2, then return 0
                        return [int]0
                    } else {
                        # If the numeric suffix is 2 or greater, subtract 1 and return the result
                        return [int]$TempNumber - [int]1
                    }
                } else {
                    # If no numeric suffix is found, then return [int]0
                    return [int]0
                }
            }

            # Split the current stack into an array
            $stackArray = $CurrentStack -split ':'
            # Initialize a new array to hold the updated stack
            $newStackArray = @()
            # Initialize variables to hold the previous function (starts out empty) and the count (starts at 1)
            $previousFunction = ""
            $count = [int]1
            foreach ($function in $stackArray) {
                $CycleIncrement = [int]1
                $NumericSuffix = [int](VbsUpdateFunctionStackExtractNumber -String "$function")
                # Check if the current function is the same as the previous function
                if ($function -match "^$previousFunction(\(\d+\))?$") {
                    # The current function is the same as the previous function and may contain a numeric suffix
                    # Add the CycleIncrement to the NumericSuffix and add that result to $count
                    [int]$LastCount = [int]$count
                    [int]$CycleCount = [int]$NumericSuffix + [int]$CycleIncrement
                    [int]$count = [int]$CycleCount + [int]$LastCount
                    # Update the last function in the updated stack with the new count
                    $newStackArray[-1] = "$previousFunction($count)"
                } else {
                    # The current function is different from the previous function
                    # Add the numeric suffix of the current function to [int]1 (if a numeric suffix exists) and reset the count to the result
                    $count = $NumericSuffix + $CycleIncrement
                    # Add the current function to the updated stack
                    $newStackArray += $function
                }
                $previousFunction = $function -replace "\(\d+\)$", ""
            }
            # Check if the new function is the same as the last function in the updated stack
            if ($newStackArray[-1] -match "^$NewFunction(\(\d+\))?$") {
                # The new function is the same as the last function in the updated stack and may contain a numeric suffix
                if ($newStackArray[-1] -match "\((\d+)\)$") {
                    # If it does, increment the count and add the numeric suffix to $count
                    $count = [int]$matches[1] + 1
                    $newStackArray[-1] = "$NewFunction($count)"
                } else {
                    # If it doesn't, add the function to the stack with a numeric suffix of 2
                    $newStackArray[-1] = "$NewFunction(2)"
                }
            } else {
                # If the new function is not the same as the last function in the updated stack, add it to the stack
                $newStackArray += $NewFunction
            }
            # Join the updated stack array back into a string
            return ($newStackArray -join ':')
        }

        # Create the timestamp field
        $epochStart = Get-Date 01.01.1970
        $tA = $([DateTimeOffset]::Now.ToUnixTimeMilliseconds())
        $tAmsStamp = ($epochStart + ([System.TimeSpan]::frommilliseconds($tA))).ToLocalTime()
        $tB = $tAmsStamp.ToString("yyyy-MM-dd HH:mm:ss.fffzzz")
        $t = -join("$tA", "|", "$tB", "|")
        $tV = -join("$tB", " ")
        # Create the ID field
        $x = -join("$VbsSessionID", "|")
        $xV = -join("$VbsSessionID", " ")
        # Create the status field
        if (-Not($Status)) {$Status = "X"}
        $s = $Status.toUpper()
        if ($s -eq "X" -or $s -eq "U" -or $s -eq "UNKNOWN") {
            $s = "[INFO][UNKNOWN]"
            $sV = "[ UNKNOWN  ] "
            $sColor = "DarkGray"
        } elseif ($s -eq "I" -or $s -eq "INF" -or $s -eq "INFO") {
            $s = "[INFO]"
            $sV = "[ INFO     ] "
            $sColor = "Gray"
        } elseif ($s -eq "E" -or $s -eq "ERR" -or $s -eq "ERROR") {
            $s = "[ERROR]"
            $sV = "[ ERROR    ] "
            $sColor = "DarkRed"
        } elseif ($s -eq "C" -or $s -eq "CRIT" -or $s -eq "CRITICAL") {
            $s = "[ERROR][CRITICAL]"
            $sV = "[ CRITICAL ] "
            $sColor = "Magenta"
        } elseif ($s -eq "W" -or $s -eq "WARN" -or $s -eq "WARNING") {
            $s = "[WARN]"
            $sV = "[ WARNING  ] "
            $sColor = "DarkYellow"
        } elseif ($s -eq "D" -or $s -eq "DEB" -or $s -eq "DEBUG") {
            $s = "[DEBUG]"
            $sV = "[ DEBUG    ] "
            $sColor = "DarkCyan"
        } elseif ($s -eq "S" -or $s -eq "SUCCESS" -or $s -eq "OK" -or $s -eq "DONE" -or $s -eq "COMPLETE" -or $s -eq "G" -or $s -eq "GOOD") {
            $s = "[INFO][SUCCESS]"
            $sV = "[ SUCCESS  ] "
            $sColor = "DarkGreen"
        } else {
            $s = "[INFO]"
            $sV = "[ INFO     ] "
            $sColor = "DarkGray"
        }
        # Create the caller field
        $c = "$Caller"
        $cTest = -join("x", "$c")
        if ("$cTest" -eq "x" -or $c -eq "$LibName") {
            ## The caller is empty or is $LibName
            $cUpdate = $LibName
            $c = -join("$LibName",":")
        } else {
            ## The caller isn't empty and isn't "$LibName".
            ## Before doing anything ...
            ## Make sure $c doesn't end with ":"
            if ($c -match ":$") {
                $c = $c -replace ":$", ""
            }
            ## Make sure $c doesn't begin with "$LibName(" and end with ")"
            $MatchString = -join("^","$LibName", "\(")
            if ($c -match "$MatchString" -and $c -match "\)$") {
                # Simply remove the "$LibName(" and ")" from the caller and continue processing as normal
                $c = $c -replace "$MatchString", "" -replace "\)$", ""
            }
            ## We need to know if it is a single caller or a sub-function (parse for ':')
            $cSplit = $c -split ':'
            ## Even if the caller contains no ':' characters, the final element of the split array will be the caller
            $cLatest = $cSplit[-1]
            ## Take action based on the number of elements in the split array
            if ($cSplit.Length -gt 1) {
                ### The caller is a sub-function. We need to update the stack
                ### To do this we must remove the final string from the stack (the current caller)
                ### but avoid removing any duplicates of the current caller which might exist in the stack
                $cOthers = $cSplit[0..($cSplit.Length - 2)] -join ':'
                ### Now we can update the stack using the function: VbsUpdateFunctionStack
                $cUpdate = (VbsUpdateFunctionStack -CurrentStack "$cOthers" -NewFunction "$cLatest")
                $c = -join("$LibName", '(', "$cUpdate", '):')
            } else {
                ### The caller is a single function so we don't need to update the stack
                $cUpdate = $c
                $c = -join("$LibName", '(', "$Caller", '):')
            }
        }
        $cDepth = (VbsFunctionStackTotalDepth -CurrentStack "$cUpdate")
        $c = -join("$c", " ")
        $cV = -join("$LibName",'(',"$cDepth",')',': ')
        # Create the message field
        $m = "$Message"
        $mTest = -join("x", "$m")
        if ("$mTest" -eq "x") {$m = '...'}
        $mV = "$m"
        # Create verbose and silent versions of the final output string
        $o = -join("$t","$x","$s","$c","$m")
        $oV = -join("$tV","$xV","$sV","$cV","$mV")
        # Derive the absolute path to the current log file and make sure it exists and then send outputs as needed
        $l = (VbsLogPath -LogDir "$LogDir")
        VbsLogRealityCheck -LogPath "$l" -LogDir "$LogDir"
        if ($Verbosity -eq $false) {
            # Write to the log only (no output to host)
            VbsLogWrite -LogPath "$l" -InputString "$o"
        } else {
            # Write to the log AND print to the host
            VbsLogWrite -LogPath "$l" -InputString "$o"
            Write-Host "$oV" -ForegroundColor $sColor
        }
        return
    }

    function _Init {
        <#
        .SYNOPSIS
            Initialize the script by creating necessary directories and backing up the script.
        .DESCRIPTION
            This function initializes the script by creating necessary directories and
            backing up the script to a specified location. It is called at the beginning
            of the script to ensure that all required directories exist and that the
            script is backed up before any operations are performed.
        #>
        Param(
            [System.Array]$DependencyDirectories = $DependencyDirectories,
            [System.String]$ScriptBackupPath = $ScriptBackupPath,
            [System.String]$ThisScriptPath = $ThisScriptPath,
            [System.Boolean]$Verbosity = $Verbosity
        )
        $thisSubFunction = "{0}" -f $MyInvocation.MyCommand
        $thisFunction = if ($null -eq $thisFunction) { $thisSubFunction } else { -join("$thisFunction", ":", "$thisSubFunction") }
        # Silently create the required directories if they do not exist
        foreach ($dir in $DependencyDirectories) {
            if (-Not (Test-Path -LiteralPath $dir -PathType Container -ErrorAction SilentlyContinue)) {
                New-Item -Path $dir -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null
            }
        }
        # If the backup script file does not exist, copy this script to the backup path
        if (-Not (Test-Path -LiteralPath "$ScriptBackupPath" -PathType Leaf -ErrorAction SilentlyContinue)) {
            Copy-Item -Path "$ThisScriptPath" -Destination "$ScriptBackupPath" -Force -ErrorAction SilentlyContinue | Out-Null
        }
    }

    function _GUI {
        <#
        .SYNOPSIS
            Create a graphical user interface for selecting a file, directory, or URL.
        .DESCRIPTION
            This function creates a graphical user interface (GUI) that allows the user
            to select a file, directory, or URL. It is used when the Interactive
            switch is enabled.
        .PARAMETER ChromeExe
            The path to the Chrome executable.
        .PARAMETER PositionX
            The X position of the Chrome window on the screen in pixels.
        .PARAMETER PositionY
            The Y position of the Chrome window on the screen in pixels.
        .PARAMETER WindowHeight
            The height of the Chrome window in pixels.
        .PARAMETER WindowWidth
            The width of the Chrome window in pixels.
        .PARAMETER Verbosity
            If set to $true, the function will print verbose messages.
        .EXAMPLE
            _GUI -ChromeExe "C:\Path\To\Chrome.exe" -PositionX 100 -PositionY 100 -WindowHeight 800 -WindowWidth 600
            Creates a GUI for selecting a file, directory, or URL with the specified parameters.
        #>
        Param(
            [Parameter(Mandatory=$true)]
            [System.String]$ChromeExe,

            [Parameter(Mandatory=$true)]
            [System.Int32]$PositionX,

            [Parameter(Mandatory=$true)]
            [System.Int32]$PositionY,

            [Parameter(Mandatory=$true)]
            [System.Int32]$WindowHeight,

            [Parameter(Mandatory=$true)]
            [System.Int32]$WindowWidth,

            [Parameter(Mandatory=$false)]
            [System.Boolean]$Verbosity = $Verbosity
        )
        $thisSubFunction = "{0}" -f $MyInvocation.MyCommand
        $thisFunction = if ($null -eq $thisFunction) { $thisSubFunction } else { -join("$thisFunction", ":", "$thisSubFunction") }
        # Load the necessary assemblies
        Add-Type -AssemblyName System.Windows.Forms
        Add-Type -AssemblyName System.Drawing
        # --- GUI Setup ---
        $form = New-Object System.Windows.Forms.Form
        $form.Text = 'Chrome Launcher Settings'
        $form.Size = New-Object System.Drawing.Size(420, 380) # Adjusted size
        $form.StartPosition = 'CenterScreen'
        $form.FormBorderStyle = 'FixedDialog'
        $form.MaximizeBox = $false
        $form.MinimizeBox = $false
        # --- Target Type Selection ---
        $labelTargetType = New-Object System.Windows.Forms.Label
        $labelTargetType.Text = 'Target Type:'
        $labelTargetType.Location = New-Object System.Drawing.Point(20, 23)
        $labelTargetType.AutoSize = $true
        $form.Controls.Add($labelTargetType)
        $comboBoxTargetType = New-Object System.Windows.Forms.ComboBox
        $comboBoxTargetType.Location = New-Object System.Drawing.Point(120, 20)
        $comboBoxTargetType.Size = New-Object System.Drawing.Size(260, 25)
        $comboBoxTargetType.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList # Prevent free text
        $comboBoxTargetType.Items.AddRange(@('URL', 'File', 'Directory'))
        $comboBoxTargetType.SelectedIndex = 0 # Default to URL
        $form.Controls.Add($comboBoxTargetType)
        # --- URL Input ---
        $labelUrl = New-Object System.Windows.Forms.Label
        $labelUrl.Text = 'URL:'
        $labelUrl.Location = New-Object System.Drawing.Point(20, 58)
        $labelUrl.AutoSize = $true
        $labelUrl.Visible = $true # Visible by default
        $form.Controls.Add($labelUrl)
        $textBoxUrl = New-Object System.Windows.Forms.TextBox
        $textBoxUrl.Location = New-Object System.Drawing.Point(120, 55)
        $textBoxUrl.Size = New-Object System.Drawing.Size(260, 25)
        $textBoxUrl.Visible = $true # Visible by default
        $form.Controls.Add($textBoxUrl)
        # --- File/Directory Path Input ---
        $labelPath = New-Object System.Windows.Forms.Label
        $labelPath.Text = 'Path:' # Text will change dynamically
        $labelPath.Location = New-Object System.Drawing.Point(20, 58)
        $labelPath.AutoSize = $true
        $labelPath.Visible = $false # Hidden by default
        $form.Controls.Add($labelPath)
        $textBoxPath = New-Object System.Windows.Forms.TextBox
        $textBoxPath.Location = New-Object System.Drawing.Point(120, 55)
        $textBoxPath.Size = New-Object System.Drawing.Size(175, 25)
        $textBoxPath.ReadOnly = $true
        $textBoxPath.Visible = $false # Hidden by default
        $form.Controls.Add($textBoxPath)
        $buttonBrowse = New-Object System.Windows.Forms.Button
        $buttonBrowse.Text = 'Browse...' # Text will change dynamically
        $buttonBrowse.Location = New-Object System.Drawing.Point(300, 54)
        $buttonBrowse.Size = New-Object System.Drawing.Size(80, 27)
        $buttonBrowse.Visible = $false # Hidden by default
        $form.Controls.Add($buttonBrowse)
        # --- Window Size ---
        $labelHeight = New-Object System.Windows.Forms.Label
        $labelHeight.Text = 'Window Height:'
        $labelHeight.Location = New-Object System.Drawing.Point(20, 113)
        $labelHeight.AutoSize = $true
        $form.Controls.Add($labelHeight)
        $numericUpDownHeight = New-Object System.Windows.Forms.NumericUpDown
        $numericUpDownHeight.Location = New-Object System.Drawing.Point(120, 110)
        $numericUpDownHeight.Size = New-Object System.Drawing.Size(80, 25)
        $numericUpDownHeight.Minimum = 100
        $numericUpDownHeight.Maximum = 6000 # Reasonable max
        $numericUpDownHeight.Value = $WindowHeight # Default
        $form.Controls.Add($numericUpDownHeight)
        $labelWidth = New-Object System.Windows.Forms.Label
        $labelWidth.Text = 'Window Width:'
        $labelWidth.Location = New-Object System.Drawing.Point(210, 113)
        $labelWidth.AutoSize = $true
        $form.Controls.Add($labelWidth)
        $numericUpDownWidth = New-Object System.Windows.Forms.NumericUpDown
        $numericUpDownWidth.Location = New-Object System.Drawing.Point(300, 110)
        $numericUpDownWidth.Size = New-Object System.Drawing.Size(80, 25)
        $numericUpDownWidth.Minimum = 100
        $numericUpDownWidth.Maximum = 6000 # Reasonable max
        $numericUpDownWidth.Value = $WindowWidth # Default
        $form.Controls.Add($numericUpDownWidth)
        # --- Window Position ---
        $labelPosY = New-Object System.Windows.Forms.Label
        $labelPosY.Text = 'Position Y:'
        $labelPosY.Location = New-Object System.Drawing.Point(20, 153)
        $labelPosY.AutoSize = $true
        $form.Controls.Add($labelPosY)
        $numericUpDownPosY = New-Object System.Windows.Forms.NumericUpDown
        $numericUpDownPosY.Location = New-Object System.Drawing.Point(120, 150)
        $numericUpDownPosY.Size = New-Object System.Drawing.Size(80, 25)
        $numericUpDownPosY.Minimum = 0
        $numericUpDownPosY.Maximum = 6000 # Reasonable max
        $numericUpDownPosY.Value = $PositionY # Default
        $form.Controls.Add($numericUpDownPosY)
        $labelPosX = New-Object System.Windows.Forms.Label
        $labelPosX.Text = 'Position X:'
        $labelPosX.Location = New-Object System.Drawing.Point(210, 153)
        $labelPosX.AutoSize = $true
        $form.Controls.Add($labelPosX)
        $numericUpDownPosX = New-Object System.Windows.Forms.NumericUpDown
        $numericUpDownPosX.Location = New-Object System.Drawing.Point(300, 150)
        $numericUpDownPosX.Size = New-Object System.Drawing.Size(80, 25)
        $numericUpDownPosX.Minimum = 0
        $numericUpDownPosX.Maximum = 6000 # Reasonable max
        $numericUpDownPosX.Value = $PositionX # Default
        $form.Controls.Add($numericUpDownPosX)
        # --- Submit / Cancel Buttons ---
        $buttonSubmit = New-Object System.Windows.Forms.Button
        $buttonSubmit.Text = 'Launch Chrome'
        $buttonSubmit.Location = New-Object System.Drawing.Point(100, 280)
        $buttonSubmit.Size = New-Object System.Drawing.Size(100, 30)
        $buttonSubmit.DialogResult = [System.Windows.Forms.DialogResult]::OK # Set DialogResult
        $form.AcceptButton = $buttonSubmit # Enter key triggers this
        $form.Controls.Add($buttonSubmit)
        $buttonCancel = New-Object System.Windows.Forms.Button
        $buttonCancel.Text = 'Cancel'
        $buttonCancel.Location = New-Object System.Drawing.Point(210, 280)
        $buttonCancel.Size = New-Object System.Drawing.Size(100, 30)
        $buttonCancel.DialogResult = [System.Windows.Forms.DialogResult]::Cancel # Set DialogResult
        $form.CancelButton = $buttonCancel # Escape key triggers this
        $form.Controls.Add($buttonCancel)
        # --- Event Handlers ---
        # ComboBox Selection Change Event Handler
        $comboBoxTargetType.Add_SelectedIndexChanged({
            $selectedType = $comboBoxTargetType.SelectedItem
            # Hide all target-specific controls initially
            $labelUrl.Visible = $false
            $textBoxUrl.Visible = $false
            $labelPath.Visible = $false
            $textBoxPath.Visible = $false
            $buttonBrowse.Visible = $false
            # Clear inputs when switching
            $textBoxUrl.Text = ''
            $textBoxPath.Text = ''
            # Show controls based on selection
            switch ($selectedType) {
                'URL' {
                    $labelUrl.Visible = $true
                    $textBoxUrl.Visible = $true
                    $textBoxUrl.Focus() # Set focus to URL input
                }
                'File' {
                    $labelPath.Text = 'File:'
                    $labelPath.Visible = $true
                    $textBoxPath.Visible = $true
                    $buttonBrowse.Text = 'Select File'
                    $buttonBrowse.Visible = $true
                }
                'Directory' {
                    $labelPath.Text = 'Directory:'
                    $labelPath.Visible = $true
                    $textBoxPath.Visible = $true
                    $buttonBrowse.Text = 'Select Directory'
                    $buttonBrowse.Visible = $true
                }
            }
        })
        # Browse Button Click Event Handler
        $buttonBrowse.Add_Click({
            $selectedType = $comboBoxTargetType.SelectedItem
            $userHome = [Environment]::GetFolderPath('UserProfile') # Start in user's home

            if ($selectedType -eq 'File') {
                $openFileDialog = New-Object System.Windows.Forms.OpenFileDialog
                $openFileDialog.InitialDirectory = $userHome
                $openFileDialog.Filter = "All files (*.*)|*.*" # This filter can be customized if necessary
                $openFileDialog.Title = "Select File"

                if ($openFileDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
                    $textBoxPath.Text = $openFileDialog.FileName
                }
                $openFileDialog.Dispose() # Clean up dialog resources
            }
            elseif ($selectedType -eq 'Directory') {
                $folderBrowserDialog = New-Object System.Windows.Forms.FolderBrowserDialog
                $folderBrowserDialog.Description = "Select Directory"
                $folderBrowserDialog.SelectedPath = $userHome

                if ($folderBrowserDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
                    $textBoxPath.Text = $folderBrowserDialog.SelectedPath
                }
                $folderBrowserDialog.Dispose() # Clean up dialog resources
            }
        })
        # --- Initialize UI State based on default selection ---
        # Manually trigger the handler once to set the initial visibility
        # This requires accessing the underlying delegate list
        $eventHandler = $comboBoxTargetType_SelectedIndexChanged # Get the script block
        if ($eventHandler) {
            # Simulate the event trigger with $null arguments
            . ($eventHandler.ScriptBlock) $null $null
        }
        # --- Show Form and Capture Results ---
        $result = $form.ShowDialog()
        # --- Process Form Results ---
        if ($result -eq [System.Windows.Forms.DialogResult]::OK) {
            # Retrieve values from the controls
            $script:TargetType = $comboBoxTargetType.SelectedItem
            $script:WindowHeight = $numericUpDownHeight.Value
            $script:WindowWidth = $numericUpDownWidth.Value
            $script:WindowPosX = $numericUpDownPosX.Value
            $script:WindowPosY = $numericUpDownPosY.Value
            # Determine the target value based on the type
            $script:TargetValue = $null
            if ($script:TargetType -eq 'URL') {
                $script:TargetValue = $textBoxUrl.Text
            } else { # File or Directory
                $script:TargetValue = $textBoxPath.Text
            }
            # --- Input Validation ---
            if ([string]::IsNullOrWhiteSpace($script:TargetValue)) {
                [System.Windows.Forms.MessageBox]::Show(
                    "The target $script:TargetType cannot be empty.",
                    "Input Error",
                    [System.Windows.Forms.MessageBoxButtons]::OK,
                    [System.Windows.Forms.MessageBoxIcon]::Warning)
                Vbs -Caller "$thisFunction" -Status w -Message "Submission blocked due to empty target." -Verbosity $Verbosity
                # Re-show the form for correction
                $result = $form.ShowDialog()
                if ($result -eq [System.Windows.Forms.DialogResult]::OK) {
                    # Re-run the input retrieval and validation logic
                    $script:TargetType = $comboBoxTargetType.SelectedItem
                    $script:WindowHeight = $numericUpDownHeight.Value
                    $script:WindowWidth = $numericUpDownWidth.Value
                    $script:WindowPosX = $numericUpDownPosX.Value
                    $script:WindowPosY = $numericUpDownPosY.Value
                    if ($script:TargetType -eq 'URL') {
                        $script:TargetValue = $textBoxUrl.Text
                    } else { # File or Directory
                        $script:TargetValue = $textBoxPath.Text
                    }
                    # Re-validate the input
                    if ([string]::IsNullOrWhiteSpace($script:TargetValue)) {
                        [System.Windows.Forms.MessageBox]::Show(
                            "The target $script:TargetType cannot be empty.",
                            "Input Error",
                            [System.Windows.Forms.MessageBoxButtons]::OK,
                            [System.Windows.Forms.MessageBoxIcon]::Warning
                        )
                        Vbs -Caller "$thisFunction" -Status w -Message "Submission blocked again due to empty target." -Verbosity $Verbosity
                        return # Exit the function if validation fails a second time
                    }
                } else {
                    Vbs -Caller "$thisFunction" -Status w -Message "Form cancelled by user after validation failure." -Verbosity $Verbosity
                    return # Exit the function if the user cancels the form
                }
            }
            # Redeclare fundamental variables based on the form inputs
            $PositionX = $script:WindowPosX
            $PositionY = $script:WindowPosY
            $Target = $script:TargetValue
            $TargetType = $script:TargetType.ToLower()
            $WindowHeight = $script:WindowHeight
            $WindowWidth = $script:WindowWidth
            # Display all of the collected values in PowerShell verbosity messages and/or logging
            Vbs -Caller "$thisFunction" -Status d -Message "--- Form Submitted ---" -Verbosity $Verbosity
            Vbs -Caller "$thisFunction" -Status d -Message "Target Type: $TargetType" -Verbosity $Verbosity
            Vbs -Caller "$thisFunction" -Status d -Message "Target Value: $Target" -Verbosity $Verbosity
            Vbs -Caller "$thisFunction" -Status d -Message "Window Height: $WindowHeight" -Verbosity $Verbosity
            Vbs -Caller "$thisFunction" -Status d -Message "Window Width: $WindowWidth" -Verbosity $Verbosity
            Vbs -Caller "$thisFunction" -Status d -Message "Window Pos X: $PositionX" -Verbosity $Verbosity
            Vbs -Caller "$thisFunction" -Status d -Message "Window Pos Y: $PositionY" -Verbosity $Verbosity
            Vbs -Caller "$thisFunction" -Status d -Message "----------------------" -Verbosity $Verbosity
            # --- Construct Chrome Arguments ---
            # Prepare target (ensure file paths are properly URI encoded)
            $TargetString = Format-TargetString -Target "$Target" -TargetType "$TargetType" -PositionX $PositionX -PositionY $PositionY -WindowHeight $WindowHeight -WindowWidth $WindowWidth -Verbosity $Verbosity
            $ChromeArgs = Get-ChromeArgs -TargetString "$TargetString" -WindowHeight $WindowHeight -WindowWidth $WindowWidth -PositionX $PositionX -PositionY $PositionY -Verbosity $Verbosity
            $ChromeArgsString = $ChromeArgs -join ' '
            # Log the Chrome path and arguments to be used
            Vbs -Caller "$thisFunction" -Status i -Message "Launching Chrome..." -Verbosity $Verbosity
            Vbs -Caller "$thisFunction" -Status d -Message "Executable: $ChromeExe" -Verbosity $Verbosity
            Vbs -Caller "$thisFunction" -Status d -Message "Arguments: $ChromeArgsString" -Verbosity $Verbosity
            # Use the sibling function to launch Chrome with the constructed arguments
            Launch-ChromeWindow -ChromeExe "$ChromeExe" -ChromeArgs "$ChromeArgs" -TargetType $TargetType -WindowHeight $WindowHeight -WindowWidth $WindowWidth -PositionX $PositionX -PositionY $PositionY -Verbosity $Verbosity
        } else {
            Vbs -Caller "$thisFunction" -Status w -Message "Form cancelled by user." -Verbosity $Verbosity
        }
        # --- Clean up form resources ---
        $form.Dispose()
    }

#______________________________________________________________________________
# Declare variables and arrays

    # Situational awareness and internal routes variables
    $Sep = [IO.Path]::DirectorySeparatorChar
    $SessionToken = [System.GUID]::NewGuid().ToString().Replace('-','')
    $HereNow = ($PWD | Select-Object -Expand Path) -join '`n'
    $ThisScriptPath = $MyInvocation.MyCommand.Path
    $ThisScriptDirectory = $ThisScriptPath | Split-Path
    $ThisScriptName = $MyInvocation.MyCommand.Name
    $ThisScriptBaseName = (Get-Item -Path $ThisScriptPath).BaseName
    $ThisScript = $ThisScriptPath | Split-Path -Leaf
    $thisSubFunction = "{0}" -f $MyInvocation.MyCommand
    $thisFunction = if ($null -eq $thisFunction) { $thisSubFunction } else { -join("$thisFunction", ":", "$thisSubFunction") }
    $D_AppData = -join("$D_UserHome","$Sep","AppData")
    $D_AppData_Local = -join("$D_AppData","$Sep","Local")
    $D_ScriptData = -join("$D_AppData_Local","$Sep","$ThisScriptBaseName")
    $D_ScriptData_Bin = -join("$D_ScriptData","$Sep","bin")
    $D_ScriptData_Demo = -join("$D_ScriptData","$Sep","demo")
    $D_ScriptData_Ico = -join("$D_ScriptData","$Sep","ico")
    $D_ScriptData_Logs = -join("$D_ScriptData","$Sep","logs")
    $ScriptBackupPath = -join("$D_ScriptData_Bin","$Sep","$ThisScriptName")
    # Declare the array of dependency directories
    $DependencyDirectories = @(
        "$D_ScriptData",
        "$D_ScriptData_Bin",
        "$D_ScriptData_Demo",
        "$D_ScriptData_Ico",
        "$D_ScriptData_Logs"
    )
    _Init -DependencyDirectories $DependencyDirectories -ScriptBackupPath $ScriptBackupPath -ThisScriptPath $ThisScriptPath
    # Initialize the ChromeArgs as an array (so we can reliably fill it up later)
    $ChromeArgs = @()

#______________________________________________________________________________
## Execute Operations

    # Catch help text requests
    if (($Help) -or ($PSCmdlet.ParameterSetName -eq 'HelpText')) {
        Get-Help $ThisScriptPath -Detailed
        exit
    }
    # Define the Chrome path variable
    $ChromeExe = Get-ChromePath -Verbosity $Verbosity
    # If Chrome is not found, print an error message and exit the script
    if (-Not($ChromeExe)) {
        Vbs -Caller "$thisFunction" -Status e -Message "Chrome not found. Exiting script." -Verbosity $Verbosity
        exit
    }
    # Determine if the script is running in interactive mode or not
    if ($Interactive) {
        # If we're running in interactive mode, call the subfunction that handles the GUI processes.
        _GUI -ChromeExe $ChromeExe -PositionX $PositionX -PositionY $PositionY -WindowHeight $WindowHeight -WindowWidth $WindowWidth -Verbosity $Verbosity
    } else {
        # Detect the type of target (file, directory, or URL)
        $TargetType = Detect-TargetType -Target "$Target" -Verbosity $Verbosity
        # If the target is null, print an error message and exit the script
        if ($TargetType -eq "null") {
            Vbs -Caller "$thisFunction" -Status e -Message "The target '$Target' is invalid. Exiting script." -Verbosity $Verbosity
            exit
        }
        # Format the '--app=' argument based on the target type
        $TargetString = Format-TargetString -Target "$Target" -TargetType "$TargetType" -Verbosity $Verbosity -PositionX $PositionX -PositionY $PositionY -WindowHeight $WindowHeight -WindowWidth $WindowWidth
        # Construct the Chrome arguments based on the provided parameters
        $ChromeArgs = Get-ChromeArgs -TargetString "$TargetString" -WindowHeight $WindowHeight -WindowWidth $WindowWidth -PositionX $PositionX -PositionY $PositionY -Verbosity $Verbosity
        # Log the chrome path to be invoked and the arguments to be used
        Vbs -Caller "$thisFunction" -Status i -Message "Invoking chrome at: $ChromeExe" -Verbosity $Verbosity
        Vbs -Caller "$thisFunction" -Status i -Message "Invoking chrome with arguments: $ChromeArgs" -Verbosity $Verbosity
        # Use the subfunction to handle launching Chrome
        Launch-ChromeWindow -ChromeExe "$ChromeExe" -ChromeArgs "$ChromeArgs" -TargetType $TargetType -WindowHeight $WindowHeight -WindowWidth $WindowWidth -PositionX $PositionX -PositionY $PositionY -Verbosity $Verbosity
    }
    exit

#______________________________________________________________________________
## End of Script