#Takes imput file and pulls download links from it and saves the file.
$net = New-Object Net.WebClient
$link_grab = get-content .\linkz.txt
#To download links list from a link comment the previous line and ncomment the next
#$link_grab = $net.DownloadString("(insert link to list here)")
$int2 = 0
for ($i = 0; $i -le $lines.Lines+999; $i++) { 
$link = ($link_grab -split '\n')[$int2] 
if ($link) {
$lines = echo $link | Measure-Object -Line
$content = $net.DownloadString("$link")
$sep = "/"
$dev = $link.split($sep)
$dev2 = echo $dev | Measure-Object -Line
$dev3 = $dev2.Lines
$int = $dev3
$filez = $dev[$int]
$file = ($filez -split '\n')[0] 
$int2 = $int2+1
echo "[#] Downloading $file ..."
if ($file) { 
echo $content > $pwd\$file
}
}
}
