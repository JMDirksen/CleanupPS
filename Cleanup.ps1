param($Path, $AgeInDays = 30, $Simulate = $true)

function main() {
    Cleanup($Path)
}

function Cleanup($path) {
    $files = Get-ChildItem $path -File -Recurse
    foreach ($file in $files) {
        [int]$ageCreated = (New-TimeSpan $file.CreationTime).TotalDays
        [int]$ageWritten = (New-TimeSpan $file.LastWriteTime).TotalDays
        $age = [Math]::Min($ageCreated, $ageWritten)

        Write-Host $file.FullName $age (DisplayInBytes $file.Length)
        if ($age -gt $AgeInDays) { 
            if (-not $Simulate) { $file.Delete() }
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
