$in = echo WOW THAT AMAZING! erykbtfeuisbrceus34563
$lol = $in -replace "a","0," -replace "b","1," -replace "c","2," -replace "d","3," -replace "e","4," -replace "f","5," -replace "g","6," -replace "h","7," -replace "i","8," -replace "j","9," -replace "k","10," -replace "l","11," -replace "m","12," -replace "n","13," -replace "o","14," -replace "p","15," -replace "q","16," -replace "r","17," -replace "s","18," -replace "t","19," -replace "u","20," -replace "v","21," -replace "w","22," -replace "x","23," -replace "y","24," -replace "z","25," -replace "A","26," -replace "B","27," -replace "C","28," -replace "D","29," -replace "E","30," -replace "F","31," -replace "G","32," -replace "H","33," -replace "I","34," -replace "J","35," -replace "K","36," -replace "L","37," -replace "M","38," -replace "N","39," -replace "O","40," -replace "P","41," -replace "Q","42," -replace "R","43," -replace "S","44," -replace "T","45," -replace "U","46," -replace "V","47," -replace "W","48," -replace "X","49," -replace "Y","50," -replace "Z","51," -replace " ","52," -replace "0","53," -replace "1","54," -replace "2","55," -replace "3","56," -replace "4","57," -replace "5","58," -replace "6","59," -replace "7","60," -replace "8","61," -replace "9","62," -replace "`","63," -replace "~","64," -replace "!","65," -replace "@","66," -replace "#","67," -replace "$","68," -replace "%","69," -replace "^","70," -replace "&","71," -replace "*","72," -replace "(","73," -replace ")","74," -replace "-","75," -replace "_","76," -replace "+","77," -replace "=","78," -replace "[","79," -replace "]","80," -replace "{","81," -replace "}","82," -replace "\","83," -replace ":","84," -replace ";","85," -replace "'","86," -replace ",","87," -replace ".","88," -replace "<","89," -replace ">","90," -replace "/","91," -replace "?","92,"

$separator = ","

$option = [System.StringSplitOptions]::None

$lol.Split($separator, $option)

foreach ($bleh in $lol) {
$ler = Get-Random -Minimum 0 -maximum 92
$num = $ler + $bleh
if $num < 92 {
$num = $num - 92
}
$nomz += 
}
