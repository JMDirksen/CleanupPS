[CmdletBinding()]
Param (
    [Parameter(Mandatory = $true)] [string] $Path,
    [Parameter(Mandatory = $true)] [ValidateRange(0, 999)] [int] $AgeInDays,
    [switch] $DeleteEmptyDirectories,
    [switch] $WhatIf
)

function Cleanup($path) {
    [int] $deletedFiles = 0
    [int] $deletedBytes = 0
    [int] $deletedDirectories = 0

    # Cleanup Files
    Get-ChildItem -Path $path -File -Recurse -Attributes Archive, Normal, Hidden, System | OldFiles | ForEach-Object {
        if ($WhatIf.IsPresent) {
            "WhatIf: Delete file '{0}' (Age: {1} Size: {2})" -f $_.FullName, $_.Age, (FormatBytes $_.Length)
        }
        else {
            Remove-Item $_.FullName -Force
            "Deleted file '{0}' (Age: {1} Size: {2})" -f $_.FullName, $_.Age, (FormatBytes $_.Length)
        }
        $deletedFiles++
        $deletedBytes += $_.Length
    }

    # Cleanup Directories
    if ($DeleteEmptyDirectories) {
        Get-ChildItem $path -Directory -Recurse | EmptyDirectories | ForEach-Object {
            if ($WhatIf.IsPresent) { 
                "WhatIf: Delete directory '{0}'" -f $_.FullName
            }
            else {
                Remove-Item $_.FullName -Recurse
                "Deleted directory '{0}'" -f $_.FullName
            }
            $deletedDirectories++
        }
    }

    # Summery
    if ($WhatIf.IsPresent) { "WhatIf: Delete {0} files ({1}) and {2} directories" -f $deletedFiles, (FormatBytes $deletedBytes), $deletedDirectories }
    else { "Deleted {0} files ({1}) and {2} directories" -f $deletedFiles, (FormatBytes $deletedBytes), $deletedDirectories }

}

filter OldFiles {
    [int] $ageCreated = (New-TimeSpan $_.CreationTime).TotalDays
    [int] $ageWritten = (New-TimeSpan $_.LastWriteTime).TotalDays
    $_ | Add-Member -NotePropertyName Age -NotePropertyValue ([Math]::Min($ageCreated, $ageWritten))
    if ($_.Age -ge $AgeInDays) { $_ }
}

filter EmptyDirectories {
    if ((Get-ChildItem $_.FullName -Recurse -File -Attributes Archive, Normal, Hidden, System).Count -eq 0) { $_ }
}

function FormatBytes($bytes) {
    $suffix = "B", "KB", "MB", "GB", "TB", "PB", "EB", "ZB", "YB"
    $index = 0
    while ($bytes -gt 1kb) {
        $bytes = $bytes / 1kb
        $index++
    } 
    "{0:N0} {1}" -f $bytes, $suffix[$index]
}

Cleanup($Path)
