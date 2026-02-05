<#
.SYNOPSIS
    Generates a detailed JSON report of a directory tree structure.

.DESCRIPTION
    Recursively analyzes a directory and creates a comprehensive JSON report containing:
    - Complete file/directory tree with metadata
    - Size metrics (bytes, words, lines)
    - Timestamps in both Unix and human-readable formats
    - Summary statistics including file extensions and depth analysis
    - Runtime metadata

    The script handles special characters in filenames, detects binary files, and provides
    detailed metrics similar to Unix tools like 'wc', 'du', and 'tree'.

.PARAMETER Directory
    The target directory to analyze. Defaults to the current working directory.
    
    Type: String
    Required: No
    Default: Current directory (Get-Location)
    
    The path is validated to ensure it exists and is a directory. Both relative and
    absolute paths are supported.

.PARAMETER File
    The output file path for the JSON report. If not specified, outputs to stdout.
    
    Type: String
    Required: No
    Default: stdout
    
    The file will be created with UTF-8 encoding. If the file exists, it will be
    overwritten without warning.

.PARAMETER Help
    Displays the full help documentation for this script.
    
    Type: Switch
    Required: No
    Aliases: h
    
    When invoked, the script calls Get-Help against itself and exits.

.OUTPUTS
    JSON object with the following structure:
    
    {
      "tree": { ... },      // Recursive directory tree with full metadata
      "summary": { ... },   // Aggregate statistics and counts
      "runtime": { ... }    // Execution metadata and timing
    }

.EXAMPLE
    .\Get-Tree.ps1
    
    Analyzes the current directory and outputs JSON to the console.

.EXAMPLE
    .\Get-Tree.ps1 -Directory "C:\Projects\MyApp"
    
    Analyzes C:\Projects\MyApp and outputs JSON to stdout.

.EXAMPLE
    .\Get-Tree.ps1 -Directory "C:\Projects\MyApp" -File "analysis.json"
    
    Analyzes C:\Projects\MyApp and saves the JSON report to analysis.json.

.EXAMPLE
    .\Get-Tree.ps1 -Directory "~/Documents" -Verbose
    
    Analyzes ~/Documents with verbose output showing progress.

.EXAMPLE
    .\Get-Tree.ps1 -Help
    .\Get-Tree.ps1 -h
    
    Displays this comprehensive help documentation.

.EXAMPLE
    $report = .\Get-Tree.ps1 -Directory "C:\Data" | ConvertFrom-Json
    Write-Host "Total files: $($report.summary.files.count)"
    Write-Host "Total size: $($report.summary.bytes) bytes"
    
    Captures the JSON output and parses it for programmatic use.

.LINK
    Get-Help
    ConvertTo-Json
    ConvertFrom-Json

.NOTES
    Author: Generated for h8rt3rmin8r by Claude
    Version: 1.1
    Last Updated: 2025-02-02
    
    COMPATIBILITY:
    - Requires PowerShell 5.1 or higher
    - Works on Windows, Linux, and macOS
    - Handles special characters including spaces, brackets, quotes, etc.
    
    PERFORMANCE:
    - Binary detection reads first 8KB of each file
    - Text files are fully read for word/line counting
    - Large directories may take several minutes to process
    - Use -Verbose flag to monitor progress
    
    LIMITATIONS:
    - Maximum JSON depth is 100 levels (PowerShell limitation)
    - Files that cannot be read are marked as binary
    - Symbolic links are classified as "other" type
    - Word counting uses whitespace splitting (similar to wc -w)

═══════════════════════════════════════════════════════════════════════════════
                           OUTPUT SCHEMA REFERENCE
═══════════════════════════════════════════════════════════════════════════════

The script outputs a JSON object with three top-level properties:

┌─────────────────────────────────────────────────────────────────────────────┐
│ ROOT OBJECT                                                                 │
└─────────────────────────────────────────────────────────────────────────────┘

{
  "tree": { <TreeNode> },       // Root directory node with recursive children
  "summary": { <Summary> },     // Aggregate statistics
  "runtime": { <Runtime> }      // Execution metadata
}

┌─────────────────────────────────────────────────────────────────────────────┐
│ TREE OBJECT (Recursive Structure)                                          │
└─────────────────────────────────────────────────────────────────────────────┘

Each node in the tree (whether file or directory) has the following structure:

{
  "type": <string>,              // Object type
  "name": <string>,              // Name with extension (no path)
  "extension": <string|null>,    // File extension or null
  "path": <string>,              // Absolute filesystem path
  "timestamps": {                // Creation and modification times
    "create_unixtime": <int>,    // Unix timestamp (seconds since epoch)
    "create_humantime": <string>,// ISO 8601 format with timezone
    "modify_unixtime": <int>,    // Unix timestamp (seconds since epoch)
    "modify_humantime": <string> // ISO 8601 format with timezone
  },
  "size": {                      // Size metrics
    "bytes": <int>,              // Total bytes
    "words": <int>,              // Word count (text files only)
    "lines": <int>,              // Line count (text files only)
    "note": <string|null>        // "binary" or null
  },
  "children": <array|null>,      // Array of TreeNode objects or null
  "depth": <int>                 // Depth in tree (0 = root)
}

PROPERTY DETAILS:

• type (string)
  Possible values:
  - "file"      : Regular file
  - "directory" : Directory/folder
  - "other"     : Special items (symbolic links, junctions, etc.)

• name (string)
  The base name of the file or directory.
  Examples: "document.pdf", "MyFolder", ".gitignore"
  
  For files with extensions: includes the extension
  For files without extensions: just the name
  For directories: the directory name

• extension (string | null)
  The file extension without the leading period.
  Examples: "txt", "json", "ps1"
  
  null if:
  - Object is a directory
  - File has no extension
  
  Note: Files starting with "." (like .gitignore) may have no extension or
        the entire name may be considered the extension depending on naming.

• path (string)
  The fully resolved absolute path to the object on the filesystem.
  Example: "C:\Users\h8rt3rmin8r\Documents\file.txt"
  
  This path can be used directly with file system operations.

• timestamps (object)
  Contains four timestamp values representing creation and modification times:
  
  - create_unixtime (integer)
    Unix timestamp (seconds since January 1, 1970 00:00:00 UTC)
    Example: 1706889600
  
  - create_humantime (string)
    ISO 8601 formatted datetime with milliseconds and timezone offset
    Format: "YYYY-MM-DDTHH:mm:ss.fff±HH:MM"
    Example: "2025-02-02T14:30:45.123-05:00"
  
  - modify_unixtime (integer)
    Unix timestamp for last modification
    Example: 1706889700
  
  - modify_humantime (string)
    ISO 8601 formatted datetime for last modification
    Example: "2025-02-02T14:32:25.456-05:00"

• size (object)
  Contains metrics about the object's size and content:
  
  - bytes (integer)
    Total size in bytes.
    For files: the file size
    For directories: the cumulative sum of all child file sizes
    Example: 2048
  
  - words (integer)
    Word count (whitespace-separated tokens).
    For text files: count of words (similar to 'wc -w')
    For binary files: 0
    For directories: sum of all child word counts
    Example: 150
  
  - lines (integer)
    Line count (newline-separated).
    For text files: count of lines (similar to 'wc -l')
    For binary files: 0
    For directories: sum of all child line counts
    Example: 25
  
  - note (string | null)
    Status indicator.
    Values:
    - null     : Normal text file or directory
    - "binary" : Binary file (words/lines not counted)
    
    A file is considered binary if it contains null bytes (0x00) in the
    first 8KB of content.

• children (array | null)
  For directories: array of TreeNode objects (may be empty array)
  For files: null
  For inaccessible directories: empty array
  
  Each element in the array follows the same TreeNode structure, creating
  a recursive tree representation.

• depth (integer)
  The depth level in the directory tree hierarchy.
  - Root directory (the target): 0
  - Direct children of root: 1
  - Grandchildren of root: 2
  - etc.
  
  Example: If analyzing "C:\Projects", then:
  - C:\Projects\ = depth 0
  - C:\Projects\src\ = depth 1
  - C:\Projects\src\main.js = depth 2

┌─────────────────────────────────────────────────────────────────────────────┐
│ SUMMARY OBJECT                                                              │
└─────────────────────────────────────────────────────────────────────────────┘

Aggregate statistics computed across the entire directory tree:

{
  "bytes": <int>,                  // Total bytes across all files
  "words": <int>,                  // Total words (text files only)
  "lines": <int>,                  // Total lines (text files only)
  "files": {                       // File statistics
    "extensions_count": <int>,     // Count of unique extensions
    "count": <int>,                // Total number of files
    "extensions": [                // Array of extension objects
      {
        "string": <string>,        // Extension (without period)
        "count": <int>             // Occurrence count
      },
      ...
    ]
  },
  "directories": {                 // Directory statistics
    "count": <int>,                // Total number of directories
    "max_depth": <int>             // Maximum depth reached
  }
}

PROPERTY DETAILS:

• bytes (integer)
  Cumulative total of all file sizes in bytes.
  Does not include filesystem overhead.
  Example: 15728640 (15 MB)

• words (integer)
  Cumulative total of words in all text files.
  Binary files are excluded from this count.
  Example: 45200

• lines (integer)
  Cumulative total of lines in all text files.
  Binary files are excluded from this count.
  Example: 8350

• files (object)
  Statistics about files in the tree:
  
  - extensions_count (integer)
    The number of unique file extensions found.
    Example: 12
    
    This counts distinct extensions. If you have 50 .txt files and 30 .json
    files, extensions_count would be 2.
  
  - count (integer)
    Total number of files (not including directories).
    Example: 237
  
  - extensions (array)
    Sorted list of extension statistics. Each element contains:
    
    • string (string)
      The file extension without the leading period.
      Example: "ps1", "json", "md"
      
      Files without extensions are not included in this array.
    
    • count (integer)
      How many files have this extension.
      Example: 15
    
    The array is sorted alphabetically by extension string.

• directories (object)
  Statistics about directories:
  
  - count (integer)
    Total number of directories found.
    Includes the root target directory.
    Example: 42
  
  - max_depth (integer)
    The maximum depth value found in the tree.
    Example: 5
    
    If max_depth is 5, the deepest file is 5 levels below the root.

┌─────────────────────────────────────────────────────────────────────────────┐
│ RUNTIME OBJECT                                                              │
└─────────────────────────────────────────────────────────────────────────────┘

Metadata about the script execution:

{
  "uuid": <string>,                // Unique run identifier
  "target": <string>,              // Absolute path to analyzed directory
  "runtime_seconds": <float>,      // Execution time in seconds
  "start_unixtime": <int>,         // Start time (Unix timestamp)
  "start_humantime": <string>,     // Start time (ISO 8601)
  "end_unixtime": <int>,           // End time (Unix timestamp)
  "end_humantime": <string>        // End time (ISO 8601)
}

PROPERTY DETAILS:

• uuid (string)
  A unique identifier for this execution run.
  Format: Standard GUID/UUID
  Example: "a3f7e9d2-4b1c-4e8a-9f2d-c5b8a7e4f3d1"
  
  Useful for tracking and correlating multiple reports.

• target (string)
  The absolute, resolved path to the directory that was analyzed.
  Example: "C:\Users\h8rt3rmin8r\Projects\MyApp"
  
  This may differ from the -Directory parameter if a relative path was used.

• runtime_seconds (float)
  Total execution time in seconds with 3 decimal places.
  Example: 2.547
  
  Includes all processing: file reading, metric calculation, and JSON generation.

• start_unixtime (integer)
  Unix timestamp when the script began execution.
  Example: 1706889600

• start_humantime (string)
  ISO 8601 formatted datetime when the script began.
  Format: "YYYY-MM-DDTHH:mm:ss.fff±HH:MM"
  Example: "2025-02-02T14:30:00.000-05:00"

• end_unixtime (integer)
  Unix timestamp when the script completed execution.
  Example: 1706889602

• end_humantime (string)
  ISO 8601 formatted datetime when the script completed.
  Example: "2025-02-02T14:30:02.547-05:00"

┌─────────────────────────────────────────────────────────────────────────────┐
│ EXAMPLE OUTPUT                                                              │
└─────────────────────────────────────────────────────────────────────────────┘

Here's a simplified example of the complete JSON structure:

{
  "tree": {
    "type": "directory",
    "name": "MyProject",
    "extension": null,
    "path": "C:\\Users\\h8rt3rmin8r\\MyProject",
    "timestamps": {
      "create_unixtime": 1706800000,
      "create_humantime": "2025-02-01T12:00:00.000-05:00",
      "modify_unixtime": 1706889600,
      "modify_humantime": "2025-02-02T12:53:20.000-05:00"
    },
    "size": {
      "bytes": 5120,
      "words": 350,
      "lines": 75,
      "note": null
    },
    "children": [
      {
        "type": "file",
        "name": "README.md",
        "extension": "md",
        "path": "C:\\Users\\h8rt3rmin8r\\MyProject\\README.md",
        "timestamps": {
          "create_unixtime": 1706800000,
          "create_humantime": "2025-02-01T12:00:00.000-05:00",
          "modify_unixtime": 1706886000,
          "modify_humantime": "2025-02-02T11:53:20.000-05:00"
        },
        "size": {
          "bytes": 2048,
          "words": 300,
          "lines": 50,
          "note": null
        },
        "children": null,
        "depth": 1
      },
      {
        "type": "file",
        "name": "app.exe",
        "extension": "exe",
        "path": "C:\\Users\\h8rt3rmin8r\\MyProject\\app.exe",
        "timestamps": {
          "create_unixtime": 1706805600,
          "create_humantime": "2025-02-01T13:33:20.000-05:00",
          "modify_unixtime": 1706889600,
          "modify_humantime": "2025-02-02T12:53:20.000-05:00"
        },
        "size": {
          "bytes": 3072,
          "words": 0,
          "lines": 0,
          "note": "binary"
        },
        "children": null,
        "depth": 1
      },
      {
        "type": "directory",
        "name": "src",
        "extension": null,
        "path": "C:\\Users\\h8rt3rmin8r\\MyProject\\src",
        "timestamps": {
          "create_unixtime": 1706801000,
          "create_humantime": "2025-02-01T12:16:40.000-05:00",
          "modify_unixtime": 1706888000,
          "modify_humantime": "2025-02-02T12:26:40.000-05:00"
        },
        "size": {
          "bytes": 0,
          "words": 0,
          "lines": 0,
          "note": null
        },
        "children": [],
        "depth": 1
      }
    ],
    "depth": 0
  },
  "summary": {
    "bytes": 5120,
    "words": 300,
    "lines": 50,
    "files": {
      "extensions_count": 2,
      "count": 2,
      "extensions": [
        {
          "string": "exe",
          "count": 1
        },
        {
          "string": "md",
          "count": 1
        }
      ]
    },
    "directories": {
      "count": 2,
      "max_depth": 1
    }
  },
  "runtime": {
    "uuid": "a3f7e9d2-4b1c-4e8a-9f2d-c5b8a7e4f3d1",
    "target": "C:\\Users\\h8rt3rmin8r\\MyProject",
    "runtime_seconds": 0.234,
    "start_unixtime": 1706889600,
    "start_humantime": "2025-02-02T12:53:20.000-05:00",
    "end_unixtime": 1706889600,
    "end_humantime": "2025-02-02T12:53:20.234-05:00"
  }
}

┌─────────────────────────────────────────────────────────────────────────────┐
│ USAGE PATTERNS                                                              │
└─────────────────────────────────────────────────────────────────────────────┘

BASIC ANALYSIS:
    .\Get-Tree.ps1 -Directory "C:\MyData"

SAVE TO FILE:
    .\Get-Tree.ps1 -Directory "C:\MyData" -File "report.json"

PARSE RESULTS IN POWERSHELL:
    $report = .\Get-Tree.ps1 -Directory "C:\MyData" | ConvertFrom-Json
    Write-Host "Found $($report.summary.files.count) files"
    Write-Host "Total size: $([math]::Round($report.summary.bytes/1MB, 2)) MB"
    
FILTER TO SPECIFIC EXTENSION:
    $report = .\Get-Tree.ps1 | ConvertFrom-Json
    $txtFiles = $report.summary.files.extensions | Where-Object {$_.string -eq "txt"}
    Write-Host "Found $($txtFiles.count) .txt files"

FIND LARGEST FILES:
    function Get-AllFiles {
        param($Node)
        if ($Node.type -eq "file") { $Node }
        if ($Node.children) {
            $Node.children | ForEach-Object { Get-AllFiles $_ }
        }
    }
    
    $report = .\Get-Tree.ps1 | ConvertFrom-Json
    $allFiles = Get-AllFiles $report.tree
    $largest = $allFiles | Sort-Object {$_.size.bytes} -Descending | Select-Object -First 10
    $largest | ForEach-Object {
        Write-Host "$($_.name): $($_.size.bytes) bytes"
    }

TRACK CHANGES OVER TIME:
    .\Get-Tree.ps1 -File "snapshot_$(Get-Date -Format 'yyyyMMdd_HHmmss').json"

═══════════════════════════════════════════════════════════════════════════════
#>

[CmdletBinding(DefaultParameterSetName = 'Default')]
Param(
    [Parameter(ParameterSetName = 'Default', Position = 0)]
    [ValidateScript({
        if (-not (Test-Path -LiteralPath $_ -PathType Container)) {throw "Directory '$_' does not exist or is not a directory."}
        $true
    })]
    [string]$Directory = (Get-Location).Path,

    [Parameter(ParameterSetName = 'Default')]
    [string]$File,

    [Parameter(ParameterSetName = 'HelpText', Mandatory = $true)]
    [Alias('h')]
    [switch]$Help
)

#region Help Handler
if ($Help -OR ($PSCmdlet.ParameterSetName -eq 'HelpText')) {
    Get-Help -Full $PSCommandPath
    exit 0
}
#endregion

#region Functions

function Get-UnixTimestamp {
    param([datetime]$DateTime)
    return [int64]([datetime]::UtcNow - (Get-Date $DateTime).ToUniversalTime()).TotalSeconds * -1 + 
           [int64]([datetime]::UtcNow - [datetime]'1970-01-01T00:00:00Z').TotalSeconds
}

function Get-IsoDateTime {
    param([datetime]$DateTime)
    return $DateTime.ToString('yyyy-MM-ddTHH:mm:ss.fffzzz')
}

function Test-BinaryFile {
    param([string]$Path)
    
    try {
        # Read first 8KB to check for null bytes
        $bytes = [System.IO.File]::ReadAllBytes($Path)
        if ($bytes.Length -eq 0) { return $false }
        
        $sampleSize = [Math]::Min(8192, $bytes.Length)
        for ($i = 0; $i -lt $sampleSize; $i++) {
            if ($bytes[$i] -eq 0) { return $true }
        }
        return $false
    }
    catch {
        Write-Verbose "Could not determine if file is binary: $Path"
        return $true  # Assume binary if we can't read it
    }
}

function Get-FileMetrics {
    param([string]$Path)
    
    $metrics = @{
        bytes = 0
        words = 0
        lines = 0
        note  = $null
    }
    
    try {
        $item = Get-Item -LiteralPath $Path -Force -ErrorAction Stop
        $metrics.bytes = $item.Length
        
        if ($item.Length -eq 0) {
            $metrics.words = 0
            $metrics.lines = 0
            return $metrics
        }
        
        if (Test-BinaryFile -Path $Path) {
            $metrics.note = "binary"
            return $metrics
        }
        
        # Read file content for word and line counting
        $content = Get-Content -LiteralPath $Path -Raw -ErrorAction Stop
        
        # Count lines
        $lineCount = (Get-Content -LiteralPath $Path -ErrorAction Stop | Measure-Object).Count
        $metrics.lines = $lineCount
        
        # Count words (similar to wc -w)
        if ($content) {
            $words = $content -split '\s+' | Where-Object { $_ -ne '' }
            $metrics.words = ($words | Measure-Object).Count
        }
    }
    catch {
        Write-Verbose "Error reading file metrics for '$Path': $_"
        $metrics.note = "binary"  # Treat unreadable files as binary
    }
    
    return $metrics
}

function Get-DirectorySize {
    param(
        [string]$Path,
        [ref]$TotalBytes,
        [ref]$TotalWords,
        [ref]$TotalLines
    )
    
    $bytes = 0
    $words = 0
    $lines = 0
    
    try {
        $items = Get-ChildItem -LiteralPath $Path -Force -ErrorAction Stop
        
        foreach ($item in $items) {
            if ($item.PSIsContainer) {
                $subMetrics = Get-DirectorySize -Path $item.FullName -TotalBytes $TotalBytes -TotalWords $TotalWords -TotalLines $TotalLines
                $bytes += $subMetrics.bytes
                $words += $subMetrics.words
                $lines += $subMetrics.lines
            }
            else {
                $fileMetrics = Get-FileMetrics -Path $item.FullName
                $bytes += $fileMetrics.bytes
                $words += $fileMetrics.words
                $lines += $fileMetrics.lines
                
                $TotalBytes.Value += $fileMetrics.bytes
                $TotalWords.Value += $fileMetrics.words
                $TotalLines.Value += $fileMetrics.lines
            }
        }
    }
    catch {
        Write-Warning "Error accessing directory '$Path': $_"
    }
    
    return @{
        bytes = $bytes
        words = $words
        lines = $lines
    }
}

function Build-TreeNode {
    param(
        [string]$Path,
        [int]$Depth,
        [ref]$FileCount,
        [ref]$DirCount,
        [ref]$Extensions,
        [ref]$MaxDepth,
        [ref]$TotalBytes,
        [ref]$TotalWords,
        [ref]$TotalLines
    )
    
    Write-Verbose "Processing: $Path (Depth: $Depth)"
    
    try {
        $item = Get-Item -LiteralPath $Path -Force -ErrorAction Stop
    }
    catch {
        Write-Warning "Cannot access item: $Path - $_"
        return $null
    }
    
    # Update max depth
    if ($Depth -gt $MaxDepth.Value) {
        $MaxDepth.Value = $Depth
    }
    
    # Determine item type
    $itemType = if ($item.PSIsContainer) {
        "directory"
    }
    elseif ($item.LinkType) {
        "other"
    }
    else {
        "file"
    }
    
    # Extract extension
    $extension = if ($item.PSIsContainer) {
        $null
    }
    elseif ($item.Extension) {
        $item.Extension.TrimStart('.')
    }
    else {
        $null
    }
    
    # Build node
    $node = [ordered]@{
        type       = $itemType
        name       = $item.Name
        extension  = $extension
        path       = $item.FullName
        timestamps = [ordered]@{
            create_unixtime  = Get-UnixTimestamp -DateTime $item.CreationTime
            create_humantime = Get-IsoDateTime -DateTime $item.CreationTime
            modify_unixtime  = Get-UnixTimestamp -DateTime $item.LastWriteTime
            modify_humantime = Get-IsoDateTime -DateTime $item.LastWriteTime
        }
        size       = $null
        children   = $null
        depth      = $Depth
    }
    
    # Handle file vs directory
    if ($item.PSIsContainer) {
        $DirCount.Value++
        
        # Get directory contents
        $childNodes = @()
        try {
            $childItems = Get-ChildItem -LiteralPath $Path -Force -ErrorAction Stop
            
            foreach ($childItem in $childItems) {
                $childNode = Build-TreeNode `
                    -Path $childItem.FullName `
                    -Depth ($Depth + 1) `
                    -FileCount $FileCount `
                    -DirCount $DirCount `
                    -Extensions $Extensions `
                    -MaxDepth $MaxDepth `
                    -TotalBytes $TotalBytes `
                    -TotalWords $TotalWords `
                    -TotalLines $TotalLines
                
                if ($childNode) {
                    $childNodes += $childNode
                }
            }
        }
        catch {
            Write-Warning "Cannot read directory contents: $Path - $_"
        }
        
        $node.children = $childNodes
        
        # Calculate directory size from children
        $dirBytes = 0
        $dirWords = 0
        $dirLines = 0
        
        foreach ($child in $childNodes) {
            $dirBytes += $child.size.bytes
            $dirWords += $child.size.words
            $dirLines += $child.size.lines
        }
        
        $node.size = [ordered]@{
            bytes = $dirBytes
            words = $dirWords
            lines = $dirLines
            note  = $null
        }
    }
    else {
        $FileCount.Value++
        
        # Track extension
        if ($extension) {
            if (-not $Extensions.Value.ContainsKey($extension)) {
                $Extensions.Value[$extension] = 0
            }
            $Extensions.Value[$extension]++
        }
        
        # Get file metrics
        $metrics = Get-FileMetrics -Path $Path
        $node.size = [ordered]@{
            bytes = $metrics.bytes
            words = $metrics.words
            lines = $metrics.lines
            note  = $metrics.note
        }
        
        # Add to totals
        $TotalBytes.Value += $metrics.bytes
        if ($metrics.note -ne "binary") {
            $TotalWords.Value += $metrics.words
            $TotalLines.Value += $metrics.lines
        }
    }
    
    return $node
}

#endregion

#region Main Script

try {
    Write-Verbose "Starting directory analysis..."
    
    # Initialize tracking variables
    $startTime = Get-Date
    $fileCount = 0
    $dirCount = 0
    $maxDepth = 0
    $totalBytes = 0
    $totalWords = 0
    $totalLines = 0
    $extensions = @{}
    
    # Resolve absolute path
    $targetPath = (Resolve-Path -LiteralPath $Directory).Path
    Write-Verbose "Target directory: $targetPath"
    
    # Build tree structure
    $tree = Build-TreeNode `
        -Path $targetPath `
        -Depth 0 `
        -FileCount ([ref]$fileCount) `
        -DirCount ([ref]$dirCount) `
        -Extensions ([ref]$extensions) `
        -MaxDepth ([ref]$maxDepth) `
        -TotalBytes ([ref]$totalBytes) `
        -TotalWords ([ref]$totalWords) `
        -TotalLines ([ref]$totalLines)
    
    # Build extensions list
    $extensionsList = @()
    foreach ($ext in $extensions.Keys | Sort-Object) {
        $extensionsList += [ordered]@{
            string = $ext
            count  = $extensions[$ext]
        }
    }
    
    # Calculate runtime
    $endTime = Get-Date
    $runtimeSeconds = [math]::Round(($endTime - $startTime).TotalSeconds, 3)
    
    # Build final report
    $report = [ordered]@{
        tree    = $tree
        summary = [ordered]@{
            bytes       = $totalBytes
            words       = $totalWords
            lines       = $totalLines
            files       = [ordered]@{
                extensions_count = $extensions.Count
                count            = $fileCount
                extensions       = $extensionsList
            }
            directories = [ordered]@{
                count     = $dirCount
                max_depth = $maxDepth
            }
        }
        runtime = [ordered]@{
            uuid            = [guid]::NewGuid().ToString()
            target          = $targetPath
            runtime_seconds = $runtimeSeconds
            start_unixtime  = Get-UnixTimestamp -DateTime $startTime
            start_humantime = Get-IsoDateTime -DateTime $startTime
            end_unixtime    = Get-UnixTimestamp -DateTime $endTime
            end_humantime   = Get-IsoDateTime -DateTime $endTime
        }
    }
    
    Write-Verbose "Analysis complete. Files: $fileCount, Directories: $dirCount, Max Depth: $maxDepth"
    
    # Convert to JSON with high depth limit to avoid truncation
    $json = $report | ConvertTo-Json -Depth 100 -Compress:$false
    
    # Output to file or stdout
    if ($File) {
        $json | Out-File -LiteralPath $File -Encoding UTF8 -Force
        Write-Verbose "Report saved to: $File"
    }
    else {
        Write-Output $json
    }
    
    Write-Verbose "Script completed successfully in $runtimeSeconds seconds."
}
catch {
    Write-Error "Fatal error during execution: $_"
    exit 1
}

#endregion