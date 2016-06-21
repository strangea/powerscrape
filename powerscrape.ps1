Param (
    [switch]$verbose
)

function Log-Message ($type, $message) {

    switch ($type) {

            "1" 
            {Write-Host "[X] " -ForegroundColor Red -NoNewline}
            "2" 
            {Write-Host "[?] " -ForegroundColor Blue -NoNewline}
            "3" 
            {Write-Host "[!] " -ForegroundColor Yellow -NoNewline}
            "4"
            {Write-Host "[*] " -ForegroundColor Magenta -NoNewline}
    }
    
        Write-Host $message -ForegroundColor White
}
 
$verbose = $true


if ($verbose) {
    Log-Message "2" "Verbosity is ON"
}

$webClient = New-Object System.Net.WebClient
$seenPastes = @()

function Get-RegexFile {
    return Get-Content ".\regex.txt"
}

function Load-SeenPastes() {
    if (Test-Path ".\seen.txt") {
        foreach ($paste in Get-Content ".\seen.txt") {
            $seenPastes += paste
        }
    }
}

function Log-Paste($paste) {
    Add-Content ".\seen.txt" $paste
    $seenPastes += $paste
}
 
 function Get-Pastes()
 {
    $result = @()
    $html = $webclient.DownloadString("http://pastebin.com/archive")
    $html | Out-File -FilePath ".\html_temp.txt"
    $html = Get-Content ".\html_temp.txt"

    [regex]$regex = '<td><img src="\/i\/t.gif"  class="i_p0" alt="" \/><a href="\/(.+)">(.+)<\/a><\/td>'

    foreach($line in $html) {
        if($line -match $regex) {
            $line = $line.TrimStart()
            $result += ($line.Replace('<td><img src="/i/t.gif"  class="i_p0" alt="" /><a href="/', "").split('"')[0])
        }
    }

    return $result
 }

 function Retrieve-PasteFromWeb($paste)
 {
        try {

            $content = $webclient.DownloadString("http://pastebin.com/raw.php?i=" + $paste)
            
            Start-Sleep -Seconds 20
        }
        catch {

            if ($_.Exception.Message -match "(404)") {
                Log-Message "1" "Unavailable : http://pastebin.com/raw.php?i=$paste"
            }

            if ($_.Exception.Message -match "(403)") {
                Log-Message "1"  "Rate Limited! : Sleeping for 10 minutes"
                $content = "EMPTY"
                start-sleep -Seconds 600
            }
            
        }
        finally {}

    return $content
}

function Search-Paste($content) {
    #$content
    foreach ($expression in $regexlist) {
        if ($content -match $expression) {
            return $true
        }
    }

    return $false
 }

$regexlist = Get-RegexFile
$i = 0
do {
    foreach ($paste in Get-Pastes) {
        if ($seenPastes -notcontains $paste) {

            if ($verbose) {
                Log-Message "2" "Checking : http://pastebin.com/raw.php?i=$paste"
            }

            $content = Retrieve-PasteFromWeb($paste)

            if (Search-Paste($content)) {
                Log-Message "3" "Found Match! : http://pastebin.com/raw.php?i=$paste"
                $content | Out-File ".\found\$paste.txt"
            }

            Log-Paste($paste)
            Start-Sleep 5
        }
    }

    Start-Sleep 5

    $i++
}
while ($true)
