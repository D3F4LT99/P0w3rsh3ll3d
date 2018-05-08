function e621-dl {
<#
.SYNOPSIS

    Download posts from e621.net

    Author: D3F4LT99
    License: BSD 3-Clause
    Required Dependencies: None
    Optional Dependencies: None
	
.DESCRIPTION

    Downloads from e621's API pulling the tags from a file.

.EXAMPLE

    C:\PS> e621-dl

.LINK

	http://www.github.com/D3F4LT99/e621-dl/
#>
$ErrorActionPreference = "SilentlyContinue"
[System.Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }
$down = 1
$net = New-Object System.Net.WebClient
$tags = Get-Content .\tags.txt -errorvariable tag_error
if ($tag_error) {
echo "[#] Tags.txt doesn't exist!"
echo $null > .\tags.txt
echo "[#] Tags.txt created for you. Add a few lines of tags to it and re-run."
return
}
$int3 = 0
for ($i = 0; $i -le 999999; $i++) { 
$linz = ($tags -split '`n')[$int3]
#$linz = $tags[$int3]
$search = $($linz -replace " ","+")
$dirz = $($linz -replace " ","_")
$dir = echo e621\$dirz
$int2 = 0
$int3 = $int3+1
if ($search) {
echo "=============================================================================="
echo "[#] Searching tags: $linz ..."
$linz = echo "https://e621.net/post/index.xml?tags=$search&limit=999999999999"
$con = cscript /nologo wget.js $linz
$minute_s = get-date -uformat %M
$day_s = get-date -uformat %d
$hour_s = get-date -uformat %H
if((Test-Path .\e621) -eq 0){mkdir .\e621 >$null}
if((Test-Path .\$dir) -eq 0){mkdir .\$dir >$null}
if((Test-Path .\$dir) -eq 1){$temp = ls -name .\$dir\*}
$proc = $con
$proc1 = echo $proc | where-object {$_ -like "*<file_url>*</file_url>*"}
$proc2 = $proc1 -replace "<file_url>","$null"
$proc3 = $proc2 -replace "</file_url>","$null"
$xml = $proc3
$nom = echo $proc3 | Measure-Object -Line
$nom2 = $nom.Lines
$nom3 = $nom2
if ($temp) { 
$lermz = echo $proc3 | where-object {$_ -like "*$temp*"}
$xml = $proc3 -replace "$lermz","$null"
}
echo "[#] Downloading $nom3 files into $dir."
foreach ($link in $xml) {
$sep = "/"
$dev = $link.split($sep)
$dev2 = echo $dev | Measure-Object -Line
$dev3 = $dev2.Lines
$int = $dev3
$filez = $dev[$int]
$sep2 = "."
$file = ($filez -split '\n')[0]
$linezd = $file.split($sep2)
$lerp = $linezd[1]
if ($lerp -eq "jpg") {$jpg = $jpg+1}
if ($lerp -eq "webm") {$webm = $webm+1}
if ($lerp -eq "png") {$png = $png+1}
if ($lerp -eq "gif") {$gif = $gif+1}
if ($lerp -eq "swf") {$swf = $swf+1}
#if ($lerp -eq "") {$ = $+1}
echo "[#] Downloading $file ..."
if ($file) { 
if ($down -eq 1) {$content = $net.DownloadFile("$link","$pwd\$dir\$file")}
if ($down -eq 2){$content = $net.DownloadFile("$link","$pwd\e621\format\$lerp\$file")}
}
}
}
}
echo "=============================================================================="
echo "[#] Files downloaded!"
if ($jpg) {echo "[#] Downloaded $jpg files of jpg type."}
if ($webm) {echo "[#] Downloaded $webm files of webm type."}
if ($png) {echo "[#] Downloaded $png files of png type."}
if ($gif) {echo "[#] Downloaded $gif files of gif type."}
if ($swf) {echo "[#] Downloaded $swf files of swf type."}
#$minute_s = get-date -uformat %M
#$day_s = get-date -uformat %d
#$hour_s = get-date -uformat %H
$minute_c = get-date -uformat %M
$day_c = get-date -uformat %d
$hour_c = get-date -uformat %H
$days = $day_s-$day_c
$minutes = $minute_c-$minute_s
$hours = $hour_c-$hour_s
echo "[#] Time elapsed: Days: $days  Hours: $hours Min: $minutes "
}
