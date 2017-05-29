function Mass-Download {
<#
.SYNOPSIS

    Download from links.

    Author: D3F4LT99
    License: BSD 3-Clause
    Required Dependencies: None
    Optional Dependencies: None
	
.DESCRIPTION

    Downloads files from a list of links into a specified folder.
	WARNING: If there are dots in the filename the extension count will mess up though the file will be fine
	
.PARAMETER Links

    Path to text file containing links.
	
.PARAMETER dlpath

    Path to download to.

.EXAMPLE

    C:\PS> Mass-Download -Links .\links.txt -dlpath .\downloads

.LINK

	http://www.github.com/D3F4LT99/Powershell/
#>
param (
        [Parameter(Mandatory = $True)]
		[string]$Links,
		[Parameter(Mandatory = $True)]
		[string]$dlpath
	)
$ErrorActionPreference = "SilentlyContinue"
#Takes imput file and pulls download links from it and saves the file.
$minute_s = get-date -uformat %M
$day_s = get-date -uformat %d
$hour_s = get-date -uformat %H
$net = New-Object Net.WebClient
$link_grab = get-content $Links -errorvariable link_error
if ($link_error) {
echo "[#] Cannot open file containing links!"
return
}
if((Test-Path $dlpath) -eq 0){
echo "[#] Download directory doesn't exist!"
}
$int2 = 0
for ($i = 0; $i -le $lines.Lines+999; $i++) { 
$link = ($link_grab -split '`n')[$int2] 
if ($link) {
$lines = echo $link | Measure-Object -Line
$sep = "/"
$dev = $link.split($sep)
$dev2 = echo $dev | Measure-Object -Line
$dev3 = $dev2.Lines
$int = $dev3
$filez = $dev[$int]
$sep2 = "."
#foreach ($line in link){$linz = $linz+1}
$file = ($filez -split '\n')[0]
#$lol1 = $file.split($sep2)
#$lol2 = echo $lol1 | Measure-Object -Line
#$lol3 = $lol2.Lines
#$lol4 = $lol3
#$lol5 = $lol1[$lol4]
#$lerp = ($lol5 -split '\n')[0]
$linezd = $file.split($sep2)
$lerp = $linezd[1]
if ($lerp -eq "exe") {$exe = $exe+1}
if ($lerp -eq "ps1") {$ps1 = $ps1+1}
if ($lerp -eq "psm1") {$psm1 = $psm1+1}
if ($lerp -eq "vbs") {$vbs = $vbs+1}
if ($lerp -eq "jpg") {$jpg = $jpg+1}
if ($lerp -eq "webm") {$webm = $webm+1}
if ($lerp -eq "png") {$png = $png+1}
if ($lerp -eq "gif") {$gif = $gif+1}
if ($lerp -eq "swf") {$swf = $swf+1}
if ($lerp -eq "bat") {$bat = $bat+1}
if ($lerp -eq "img") {$img = $img+1}
if ($lerp -eq "iso") {$iso = $iso+1}
if ($lerp -eq "html") {$html = $html+1}
if ($lerp -eq "js") {$js = $js+1}
if ($lerp -eq "jar") {$jar = $jar+1}
if ($lerp -eq "c") {$c = $c+1}
if ($lerp -eq "cpp") {$cpp = $cpp+1}
if ($lerp -eq "txt") {$txt = $txt+1}
if ($lerp -eq "zip") {$zip = $zip+1}
if ($lerp -eq "rar") {$rar = $rar+1}
if ($lerp -eq "7z") {$7z = $7z+1}
if ($lerp -eq "h") {$h = $h+1}
if ($lerp -eq "ico") {$ico = $ico+1}
if ($lerp -eq "dll") {$dll = $dll+1}
if ($lerp -eq "sys") {$sys = $sys+1}
if ($lerp -eq "sln") {$sln = $sln+1}
if ($lerp -eq "vcxproj") {$vcxproj = $vcxproj+1}
if ($lerp -eq "msi") {$msi = $msi+1}
#if ($lerp -eq "") {$ = $+1}
$int2 = $int2+1
echo "[#] Downloading $file ..."
if ($file) { 
$content = $net.DownloadFile("$link","$dlpath\$file")
}
}
}
echo "=============================================================================="
echo "[#] Downloaded all $int files!"
if ($exe) {echo "[#] Downloaded $exe files of exe type."}
if ($ps1) {echo "[#] Downloaded $ps1 files of ps1 type."}
if ($psm1) {echo "[#] Downloaded $psm1 files of psm1 type."}
if ($vbs) {echo "[#] Downloaded $vbs files of vbs type."}
if ($jpg) {echo "[#] Downloaded $jpg files of jpg type."}
if ($webm) {echo "[#] Downloaded $webm files of webm type."}
if ($png) {echo "[#] Downloaded $png files of png type."}
if ($gif) {echo "[#] Downloaded $gif files of gif type."}
if ($swf) {echo "[#] Downloaded $swf files of swf type."}
if ($bat) {echo "[#] Downloaded $bat files of bat type."}
if ($img) {echo "[#] Downloaded $img files of img type."}
if ($iso) {echo "[#] Downloaded $iso files of iso type."}
if ($html) {echo "[#] Downloaded $html files of HTML type."}
if ($js) {echo "[#] Downloaded $js files of js type."}
if ($jar) {echo "[#] Downloaded $jar files of jar type."}
if ($c) {echo "[#] Downloaded $c files of c type."}
if ($cpp) {echo "[#] Downloaded $cpp files of cpp type."}
if ($txt) {echo "[#] Downloaded $txt files of txt type."}
if ($zip) {echo "[#] Downloaded $zip files of zip type."}
if ($rar) {echo "[#] Downloaded $rar files of rar type."}
if ($7z) {echo "[#] Downloaded $7z files of 7z type."}
if ($h) {echo "[#] Downloaded $h files of h type."}
if ($ico) {echo "[#] Downloaded $ico files of ico type."}
if ($dll) {echo "[#] Downloaded $dll files of dll type."}
if ($sys) {echo "[#] Downloaded $sys files of sys type."}
if ($sln) {echo "[#] Downloaded $sln files of sln type."}
if ($vcxproj) {echo "[#] Downloaded $vcxproj files of vcxproj type."}
if ($msi) {echo "[#] Downloaded $msi files of msi type."}
#if ($) {echo "[#] Downloaded $ files of  type."}
#$minute_s = get-date -uformat %M
#$day_s = get-date -uformat %d
#$hour_s = get-date -uformat %H
$minute_c = get-date -uformat %M
$day_c = get-date -uformat %d
$hour_c = get-date -uformat %H
$days = $day_c-$day_s
$minutes = $minute_c-$minute_s
$hours = $hour_c-$hour_s
#Time elapsed is broken
echo "[#] Time elapsed: Days: $days  Hours: $hours Min: $minutes "
}
