<#
.SYNOPSIS
    Generates a comprehensive JSON map of Unicode characters.

.DESCRIPTION
    This script iterates through the Unicode range from 1 to 129791 (U+0001 to U+1FAFF).
    It outputs a JSON list of objects, each containing the character's hex value,
    category, multi-language escape sequences (PS, Bash, Python), bit-depth, and a safety flag.

    It handles:
    - Basic Latin and Control characters (16-bit)
    - Emoticons (Faces), Transport, and Misc Symbols (32-bit)
    - Reserved Surrogate ranges (0xD800 - 0xDFFF)
    - Private Use Areas

    The output is piped directly to stdout as a JSON string unless an output file is specified.

    This script defaults to generating all characters from U+0000 to U+1FAFF (Min=0, Max=129791). This range can be adjusted via parameters.

    WARNING: If running with the default Min and Max, the output is large (~30MB+). It is recommended to pipe this to a file.

.PARAMETER Help
    Displays this help message.

.PARAMETER Min
    The minimum Unicode code point to include (default: 0).

.PARAMETER Max
    The maximum Unicode code point to include (default: 129791).

.PARAMETER Output
    The output file path to save the JSON data. If not specified, outputs to stdout.

.EXAMPLE
    .\Get-UnicodeReference.ps1 -Output "Unicode_Reference.json"
    Generates the full map and saves it to a JSON file.
#>
[CmdletBinding(SupportsShouldProcess=$false,ConfirmImpact='None',DefaultParameterSetName='Default')]
Param(
    [Parameter(Mandatory=$false,ParameterSetName='Default')]
    [Alias("minimum","lower")]
    [System.String]$Min = 0,

    [Parameter(Mandatory=$false,ParameterSetName='Default')]
    [Alias("lim","limit","maximum","upper")]
    [System.String]$Max = 129791,

    [Parameter(Mandatory=$false,ParameterSetName='Default')]
    [Alias("o","out","outputfile")]
    [System.String]$Output,

    [Parameter(Mandatory=$true,ParameterSetName='HelpText')]
    [Alias("h")]
    [Switch]$Help
)
#______________________________________________________________________________
## Declare Functions

    function Generate-UnicodeDefs {
        <#
        .SYNOPSIS
            Generates Unicode character definitions.
        #>
        [CmdletBinding(SupportsShouldProcess=$false,ConfirmImpact='None',DefaultParameterSetName='Default')]
        Param(
            [Parameter(Mandatory=$true,ParameterSetName='Default')]
            [System.String]$Min,

            [Parameter(Mandatory=$true,ParameterSetName='Default')]
            [System.String]$Max
        )

        $Min..$Max | ForEach-Object {
            $Index = $_
            $Hex = '0x{0:X}' -f $Index

            # 1. Determine Logic Flags
            $IsReserved = ($Index -ge 0xD800 -and $Index -le 0xDFFF)
            $Bits = if ($Index -le 0xFFFF) { 16 } else { 32 }

            # 2. Determine Category (PascalCase, no spaces/symbols)
            $Cat = switch ($Index) {
                # --- Standard Plane ---
                { $_ -in 0x0000..0x001F } { "Control" }
                { $_ -in 0x0020..0x007F } { "BasicLatin" }
                { $_ -in 0x0080..0x00FF } { "Latin1Supplement" }
                { $_ -ge 0xD800 -and $_ -le 0xDFFF } { "ReservedSurrogate" }
                { $_ -ge 0xE000 -and $_ -le 0xF8FF } { "PrivateUseArea" }

                # --- Emoji & Symbols Plane ---
                { $_ -ge 0x1F600 -and $_ -le 0x1F64F } { "Emoticons" }
                { $_ -ge 0x1F300 -and $_ -le 0x1F5FF } { "MiscSymbolsAndPictographs" }
                { $_ -ge 0x1F680 -and $_ -le 0x1F6FF } { "TransportAndMap" }
                { $_ -ge 0x1F900 -and $_ -le 0x1FAFF } { "SupplementalSymbols" }

                Default { 
                    # Fallback: Try to get the official Unicode category name
                    if (-not $IsReserved) {
                        $TempStr = [char]::ConvertFromUtf32($Index)
                        [System.Globalization.CharUnicodeInfo]::GetUnicodeCategory($TempStr, 0).ToString()
                    } else {
                        "Unknown"
                    }
                }
            }

            # 3. Determine "Safe" Status
            $IsSafe = $true

            if ($IsReserved) {
                $IsSafe = $false
            } else {
                if ($Bits -eq 16 -and [char]::IsControl([char]$Index)) {
                    $IsSafe = $false
                }
                if ($Cat -eq "Control") {
                    $IsSafe = $false
                }
            }

            # 4. Generate String Value (Only if Safe)
            $StringVal = $null
            if ($IsSafe) {
                $StringVal = [char]::ConvertFromUtf32($Index)
            }

            # 5. Generate Command Strings for Multiple Languages

            ## A. PowerShell (Renamed from 'cmd')
            if ($Bits -eq 32) {
                $CmdPs1 = '$([char]::ConvertFromUtf32({0}))' -f $Hex
            } else {
                $CmdPs1 = '$([char]{0})' -f $Hex
            }

            ## B. Bash (printf)
            ## Bash uses \U for 32-bit (8-digit hex) and \u for 16-bit (4-digit hex)
            if ($Bits -eq 32) {
                $CmdSh = "printf '\U{0:X8}'" -f $Index
            } else {
                $CmdSh = "printf '\u{0:X4}'" -f $Index
            }

            ## C. Python 3 (print)
            ## Python 3 uses \U for 32-bit (8-digit hex) and \u for 16-bit (4-digit hex)
            if ($Bits -eq 32) {
                $CmdPy = "print('\U{0:X8}')" -f $Index
            } else {
                $CmdPy = "print('\u{0:X4}')" -f $Index
            }

            ## D. JavaScript (console.log)
            ## Modern JS uses \u{X...} syntax which handles variable length automatically
            #$CmdJs = "console.log('\u{{{0:X}}}')" -f $Index

            # 6. Output Object
            [PSCustomObject]@{ 
                index    = $Index
                hex      = $Hex
                category = $Cat
                cmd_ps1  = $CmdPs1
                cmd_sh   = $CmdSh
                cmd_py   = $CmdPy
                bits     = $Bits
                safe     = $IsSafe
                string   = $StringVal
            }
        } | ConvertTo-Json -Depth 2
    }

#______________________________________________________________________________
## Declare Variables and Arrays

    $ThisScriptPath = $MyInvocation.MyCommand.Path

#______________________________________________________________________________
## Execute Operations

    # Catch help text requests
    if (($Help) -or ($PSCmdlet.ParameterSetName -eq 'HelpText')) {
        Get-Help $ThisScriptPath -Detailed
        exit
    }

    # Generate Unicode Definitions
    if ([string]::IsNullOrWhiteSpace($Output)) {
        # If no output file is specified, write to stdout
        Generate-UnicodeDefs -Min $Min -Max $Max
    } else {
        # Write to indicated file (UTF8 + Force)
        Generate-UnicodeDefs -Min $Min -Max $Max | Out-File -FilePath $Output -Encoding utf8 -Force
    }

#______________________________________________________________________________
## End of script