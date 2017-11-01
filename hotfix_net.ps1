$slur = get-hotfix | select HotFixID | Where-Object {$_ -like "KB*"}
$networked_computers = net view /all | Where-Object {$_ -like "*\\*"}
$slur2 = $slur
$int2 = 0
$int3 = 0
foreach ($comp in $networked_computers) {
#for ($i = 0; $i -le $lines.Lines+999; $i++) { 
#$link = $slur2[$int2] 
#if ($link) {
#$lines = echo $link | Measure-Object -Line
#foreach ($kb in $slur2) {
#for ($iz = 0; $iz -le $linez.Lines+999; $i++) { 
#$nom = $slur2[$int3] 
#$linez = echo $nom | Measure-Object -Line
#$int3 = $in3+1
echo "[#] Checking $kb against $comp to see if its installed..."
get-hotfix -Id $kb -ComputerName $comp
}
$int2 = $int2+1
}
}
}
}
