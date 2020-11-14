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
    [int] $deletedFiles = 0
    [int] $deletedBytes = 0
    [int] $deletedDirectories = 0

    $files = Get-ChildItem -Path $path -File -Recurse
    foreach ($file in $files) {
        [int]$ageCreated = (New-TimeSpan $file.CreationTime).TotalDays
        [int]$ageWritten = (New-TimeSpan $file.LastWriteTime).TotalDays
        $age = [Math]::Min($ageCreated, $ageWritten)

        if ($age -ge $AgeInDays) {
            if ($WhatIf.IsPresent) {
                "WhatIf: Delete file '{0}' (Age: {1} Size: {2})" -f $file.FullName, $age, (DisplayInBytes $file.Length)
            }
            else {
                "Delete file '{0}' (Age: {1} Size: {2})" -f $file.FullName, $age, (DisplayInBytes $file.Length)
                #$file.Delete()
            }
            $deletedFiles++
            $deletedBytes += $file.Length
        }
    }

    Get-ChildItem $path -Directory -Recurse | Where-Object { (Get-ChildItem $_.FullName).Count -eq 0 } | ForEach-Object {
        if ($WhatIf.IsPresent) {
            "WhatIf: Delete directory '{0}'" -f $_.FullName
        }
        else {
            #Remove-Item $_
            "Deleted directory '{0}'" -f $_.FullName
        }
        $deletedDirectories++
    }

    if ($WhatIf.IsPresent) { "WhatIf: Delete {0} files ({1}) and {2} directories" -f $deletedFiles, (DisplayInBytes $deletedBytes), $deletedDirectories }
    else { "Deleted {0} files ({1}) and {2} directories" -f $deletedFiles, (DisplayInBytes $deletedBytes), $deletedDirectories }

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
