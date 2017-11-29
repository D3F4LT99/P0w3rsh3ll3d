<#
#################################################
# Group Policy Preferences Password check by:   #
#      Nathan V                                 #
#      Cyber Security Analyst                   #
#      http://nathanv.com                       #
#                                               #
# For assistance and new versions contact       #
#      nathan.v@gmail.com                       #
# This file updated:                14 Dec 2012 #
#################################################
# This script (c)2012 Nathan V : License: GPLv2 #
# This is free software, and you are welcome to #
# redistribute it under certain conditions; See #
# http://www.gnu.org/licenses/gpl.html          #
#################################################
# Based on Get-GPPPassword by:                  #
#      Chris Campbell                           #
#      www.obscuresecurity.blogspot.com         #
#      @obscuresec                              #
#################################################
#>
Param(
    [alias("local")]
    $localfile)

# Import the Group Policy module;  required for finding the GPO name for each password.  If this fails the names will not resolve but other functions will still work.
import-module grouppolicy -ea SilentlyContinue
$results = @()  # declare dynamic results array

# Function to allow us to go to the network DIR and then return back to where we started
function cdir {
    if ($args[0] -eq '-') {
            $pwd=$OLDPWD;
        } else {
            $pwd=$args[0];
        }
        $tmp=pwd;
        if ($pwd) {
            Set-Location $pwd;
        }
    Set-Variable -Name OLDPWD -Value $tmp -Scope global;
}

#Function to pull encrypted password string from groups.xml
function parsecPassword($path) {
    try {
        [xml] $Xml = Get-Content ($Path)
        [string] $cPassword = $Xml.Groups.User.Properties.cpassword
    } catch { $cPassword = "No Password Policy Found" }
    return $cPassword
}
#Function to look to see if the administrator account is given a newname
function parseNewName($path) {
    try {
		[xml] $Xml = Get-Content ($Path)
		[string] $newName = $Xml.Groups.User.Properties.newName
		if ($newName) {
			return $newName
		} else {
			return "No Username Specified"
		}
    } catch { $newName = "Error" }
}
#Function to parse out the Username whose password is being specified
function parseUserName($path) {
    try {
        [xml] $Xml = Get-Content ($Path)
        [string] $userName = $Xml.Groups.User.Properties.userName
		if ($userName) {
			return $userName
		} else {
			return "No Username Specified"
		}
    } catch { $userName = "Error" }
}

#Function that decodes and decrypts password
function decryptPassword {
    try {
		if( $cPassword.Length -eq 0 ) {
			return "Empty Password!"
		} elseif( $cPassword.Length -gt 64 ) {
			[string]$cPassword = [string]$cPassword.Substring(0,64)
		} else {
			[string]$Pad = "=" * (4 - ($cPassword.length % 4))
		}
        $b64Decoded = [Convert]::FromBase64String($cPassword + $Pad)
        $aesObject = New-Object System.Security.Cryptography.AesCryptoServiceProvider
        [Byte[]] $aesKey = @(0x4e,0x99,0x06,0xe8,0xfc,0xb6,0x6c,0xc9,0xfa,0xf4,0x93,0x10,0x62,0x0f,0xfe,0xe8,0xf4,0x96,0xe8,0x06,0xcc,0x05,0x79,0x90,0x20,0x9b,0x09,0xa4,0x33,0xb6,0x6c,0x1b)
        $aesIV = New-Object Byte[]($aesObject.IV.Length)
        $aesObject.IV = $aesIV
        $aesObject.Key = $aesKey
        $decryptorObject = $aesObject.CreateDecryptor()
        [Byte[]] $outBlock = $decryptorObject.TransformFinalBlock($b64Decoded, 0, $b64Decoded.length)
        return [System.Text.UnicodeEncoding]::Unicode.GetString($outBlock)
    } catch { return "Decryption Failed!" }
}

# Function to find the policy name to locate where the password is valid
function getGPO($path) {
    $guid = $Path.Substring(1,36)
    try {
        $gpoName = get-gpo -guid $guid | Select-Object -ExpandProperty DisplayName
    } catch {
        $gpoName = "Unable to find GPO name"
    }
    return $gpoName
}

# Function to parse the XML, decrypt the key, and return the results.
function parseDecrypt($path) {
    $cPassword = parsecPassword $path
    $password = decryptPassword 
    $newName = parseNewName $path
    $userName = parseUserName $path
    if ($localfile -eq $null) {$gpo = getGPO $path} else {$gpo = "Local file"}
    $results = "$username, $newName, $password, $gpo"
    return $results
}
Clear-Host
if ($localfile -eq $null) {
    Write-Host "Searching $Env:UserDNSDomain for Group Policy Preferences passwords."
    Write-Host "On a large domain this may take some time. Please wait..."
    $sourceXML = Get-ChildItem -Path "\\$Env:UserDNSDomain\SYSVOL\$Env:UserDNSDomain\Policies" -recurse -name -include Groups.xml
    cdir \\$Env:UserDNSDomain\SYSVOL\$Env:UserDNSDomain\Policies\  # Due to the potential length of the filenames given a long domain name we CD to the Policies folder to shrink it down
    } else {
    Write-Host "-local used; checking file $file"
    $sourceXML = $localfile
    }

Write-Host " "
Write-Host "Username, New name (if any), Password, source GPO:"
Write-Host " "

foreach($file in $sourceXML) { 
    $results += parseDecrypt $file
    }
if ($localfile -eq $null) {cdir -}
"Username, New name (if any), Password, source GPO:" > ".\domain_passwords.txt"
foreach($result in $results) {
    Write-Host $result
    $result >> ".\domain_passwords.txt"
    }
Write-Host " "
Write-Host "List of discovered setttings saved as .\domain_passwords.txt"
