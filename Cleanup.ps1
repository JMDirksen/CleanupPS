[CmdletBinding()]
Param(
    [Parameter(Mandatory = $true)] [string] $Path,
    [Parameter(Mandatory = $true)] [int] $AgeInDays,
    [switch] $DeleteEmptyDirectories,
    [switch] $WhatIf
)

function main() {
    Cleanup($Path)
}

function Cleanup($path) {
    $files = Get-ChildItem $path -File -Recurse
    foreach ($file in $files) {
        [int]$ageCreated = (New-TimeSpan $file.CreationTime).TotalDays
        [int]$ageWritten = (New-TimeSpan $file.LastWriteTime).TotalDays
        $age = [Math]::Min($ageCreated, $ageWritten)
        $size = DisplayInBytes $file.Length

        if ($age -ge $AgeInDays) {
            if ($WhatIf.IsPresent) {
                "WhatIf: Delete file {0} (Age: {1} Size: {2})" -f $file.FullName, $age, $size
            }
            else {
                #$file.Delete()
            }
        }
    }

    if ($DeleteEmptyDirectories) {
        $dirs = Get-ChildItem $path -Directory -Recurse
        foreach ($dir in $dirs) {

        }
    }
}

function DisplayInBytes($num) {
    $suffix = "B", "KB", "MB", "GB", "TB", "PB", "EB", "ZB", "YB"
    $index = 0
    while ($num -gt 1kb) {
        $num = $num / 1kb
        $index++
    } 
    "{0:N0} {1}" -f $num, $suffix[$index]
}

main
