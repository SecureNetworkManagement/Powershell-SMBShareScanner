function Get-IPrange
{

 
param 
( 
  [string]$start, 
  [string]$end, 
  [string]$ip, 
  [string]$mask, 
  [int]$cidr 
) 
 
function IP-toINT64 () { 
  param ($ip) 
 
  $octets = $ip.split(".") 
  return [int64]([int64]$octets[0]*16777216 +[int64]$octets[1]*65536 +[int64]$octets[2]*256 +[int64]$octets[3]) 
} 
 
function INT64-toIP() { 
  param ([int64]$int) 

  return (([math]::truncate($int/16777216)).tostring()+"."+([math]::truncate(($int%16777216)/65536)).tostring()+"."+([math]::truncate(($int%65536)/256)).tostring()+"."+([math]::truncate($int%256)).tostring() )
} 
 
if ($ip) {$ipaddr = [Net.IPAddress]::Parse($ip)} 
if ($cidr) {$maskaddr = [Net.IPAddress]::Parse((INT64-toIP -int ([convert]::ToInt64(("1"*$cidr+"0"*(32-$cidr)),2)))) } 
if ($mask) {$maskaddr = [Net.IPAddress]::Parse($mask)} 
if ($ip) {$networkaddr = new-object net.ipaddress ($maskaddr.address -band $ipaddr.address)} 
if ($ip) {$broadcastaddr = new-object net.ipaddress (([system.net.ipaddress]::parse("255.255.255.255").address -bxor $maskaddr.address -bor $networkaddr.address))} 
 
if ($ip) { 
  $startaddr = IP-toINT64 -ip $networkaddr.ipaddresstostring 
  $endaddr = IP-toINT64 -ip $broadcastaddr.ipaddresstostring 
} else { 
  $startaddr = IP-toINT64 -ip $start 
  $endaddr = IP-toINT64 -ip $end 
} 
 
 
for ($i = $startaddr; $i -le $endaddr; $i++) 
{ 
  INT64-toIP -int $i 
}

}
Function Select-FolderDialog
{


    param([string]$Description="Select Folder",[string]$RootFolder="Desktop")

 [System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms") |
     Out-Null     

   $objForm = New-Object System.Windows.Forms.FolderBrowserDialog
        $objForm.Rootfolder = $RootFolder
        $objForm.Description = $Description
        $Show = $objForm.ShowDialog()
        If ($Show -eq "OK")
        {
            Return $objForm.SelectedPath
        }
        Else
        {
            Write-Error "Operation cancelled by user."
        }
    }
function Get-SharedFolder {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string]$ComputerName 
        ,
        [Parameter(Mandatory = $false)]
        [switch]$GetItem
        ,
        [Parameter(Mandatory = $false)]
        [string[]]$ColumnHeadings = @('Share name','Type')  #I suspect these differ depending on OS language?  Therefore made customisable
        ,
        [Parameter(Mandatory = $false)]
        [string]$ShareName = 'Share name' #tell us which of the properties relates to the share name
        #,
        #[Parameter(Mandatory = $false)]
        #[string[]]$Types = @('Disk') # again, likely differs with language.  Also there may be other types to include?
    )
    begin {
        [psobject[]]$Splitter = $ColumnHeadings | %{
            $ColumnHeading = $_
            $obj = new-object -TypeName PSObject -Property @{
                Name = $ColumnHeading
                StartIndex = 0
                Length = 0
            }
            $obj | Add-Member -Name Initialise -MemberType ScriptMethod {
                param([string]$header)
                process {
                    $_.StartIndex = $header.indexOf($_.Name)
                    $_.Length = ($header -replace ".*($($_.Name)\s*).*",'$1').Length
                }
            }
            $obj | Add-Member -Name GetValue -MemberType ScriptMethod {
                param([string]$line)
                process {
                    $line -replace ".{$($_.StartIndex)}(.{$($_.Length)}).*",'$1'
                }
            }
            $obj | Add-Member -Name Process -MemberType ScriptMethod {
                param([psobject]$obj,[string]$line)
                process {
                    $obj | Add-Member -Name $_.Name -MemberType NoteProperty -Value ($_.GetValue($line))
                }
            }
            $obj
        }
    }
    process {
        [string[]]$output = (NET.EXE VIEW $ComputerName)
        [string]$headers = $output[4] #find the data's heading row
        $output = $output[7..($output.Length-3)] #keep only the data rows
        $Splitter | %{$_.Initialise($headers)}
        foreach($line in $output) { 
            [psobject]$result = new-object -TypeName PSObject -Property @{ComputerName=$ComputerName;}
            $Splitter | %{$_.Process($result,$line)}
            $result | Add-Member '_ShareNameColumnName' -MemberType NoteProperty -Value $ShareName
            $result | Add-Member 'Path' -MemberType ScriptProperty -Value {("\\{0}\{1}" -f $this.ComputerName,$this."$($this._ShareNameColumnName)")}
            $result | Add-Member 'Item' -MemberType ScriptProperty -Value {Get-Item ($this.Path)}
            #$result | Add-Member -MemberType MemberSet -Name PSStandardMembers -Value ([System.Management.Automation.PSMemberInfo[]]@(New-Object System.Management.Automation.PSPropertySet(‘DefaultDisplayPropertySet’[string[]](@('ComputerName','Path') + $ColumnHeadings))))
            $result 
        }
    }
}

$pshost = get-host
$pswindow = $pshost.ui.rawui
$newsize = $pswindow.buffersize
$newsize.height = 300
$newsize.width = 115
$pswindow.buffersize = $newsize
$newsize = $pswindow.windowsize
$newsize.height = 50
$newsize.width = 115
$pswindow.windowsize = $newsize

	Write-Host "
  _________   _____  __________    _________.__                               _________                        
 /   _____/  /     \ \______   \  /   _____/|  |__  _____  _______   ____    /   _____/  ____  _____     ____  
 \_____  \  /  \ /  \ |    |  _/  \_____  \ |  |  \ \__  \ \_  __ \_/ __ \   \_____  \ _/ ___\ \__  \   /    \ 
 /        \/    Y    \|    |   \  /        \|   Y  \ / __ \_|  | \/\  ___/   /        \\  \___  / __ \_|   |  \
/_______  /\____|__  /|______  / /_______  /|___|  /(____  /|__|    \___  > /_______  / \___  >(____  /|___|  /
        \/         \/        \/          \/      \/      \/             \/          \/      \/      \/      \/ 

		
																												By Rufi746
__________________________________________________________________________________________________________________

" -ForegroundColor Red
Write-host 'This will allow you to scan systems for open shares on the network either with a file or subnet.' -BackgroundColor Black -ForegroundColor Green
Write-Host "" 
Write-Host "Please note if you are using the batch file with other credentials" -BackgroundColor Black -ForegroundColor Red
Write-Host "YOU WILL HAVE TO STORE ALL FILES IN THE PUBLIC DOCUMENTS Folder!!" -BackgroundColor Black -ForegroundColor Red
Write-Host "" 
$main = Read-Host -Prompt 'Enter subnet or file' 
Write-Host "" 
$location = Write-Host "Select a location where Script and Results are stored!" -BackgroundColor White -ForegroundColor Red | Select-FolderDialog
Write-Host "" 
$filename = Read-Host -Prompt "Enter filename for the results!" 
Write-Host "" 
If ($main -eq 'file'){
	$shares = Write-Host 'Select the Location of File with IPs or Hostnames ' | Select-FolderDialog
	Write-Host "" 
	$sname = Read-Host -Prompt 'Enter the name of the File' 
	Clear-Host
	Write-Host "Starting Share Lookup..." -ForegroundColor Cyan
	Start-Sleep -s 5	
	Write-host ""
	ForEach ($system in Get-Content $shares"\"$sname".txt")
	{
	$shre = NET.EXE VIEW $system
		if ($shre -eq $null -OR $shre -contains "There are no entries in the list." -OR $shre -contains "System error 53 has occurred." -OR $shre -contains "The network path was not found."){
		write-host "No Shares Found On $system" -BackgroundColor Red 
		Write-host "" 
		}
		else {
		Write-host "Found Shares On $system" -BackgroundColor Green -ForegroundColor Black
		Write-host ""
		$system | out-file $location"\sharesfound1.txt" -Append -NoClobber 
		}
	}
	ForEach ($system1 in Get-Content -Path $location"\sharesfound1.txt"){
		$shre2 = $system1 | Get-SharedFolder
		$shre2 | ft -Property ComputerName,'Share name','Type',Path -AutoSize | out-file $location"\"$filename".txt" -Append -NoClobber 
	}
Remove-Item $location"\sharesfound1.txt"
}

If ($main -eq 'subnet'){
	Write-Host "" 
	Write-Host 'You will be propmted to enter the network address and cidr notation seperately!!!!' -BackgroundColor White -ForegroundColor Red 
	Write-Host "" 
	$network = Read-Host -Prompt 'Enter network host address'
	Write-Host "" 
	$cidr = Read-Host -Prompt 'Enter CIDR Number without the "\"!' 
	Clear-Host 
	Write-Host " Starting Ping Sweep..."  -ForegroundColor Cyan
	Write-Host "" 
	Get-IPrange -ip $network -cidr $cidr | Out-file $location"\hosts.txt" -Append -NoClobber 
		ForEach ($host1 in Get-Content -Path $location"\hosts.txt")
		{
						
			if ($alive = Test-Connection $host1.Trim() -Quiet -Count 1){
			$host1 |Out-file $location"\alive.txt" -Append -NoClobber
			Write-Host "$host1 -UP, Host Will be Scanned" -BackgroundColor Green -ForegroundColor Black
			}
			Else{
			write-host "$host1 -Down, Host Will Not be Scanned!" -b red
			}
				
		}
	Clear-Host
	Write-Host "Starting Share Lookup..." -ForegroundColor Cyan
	
	Start-Sleep -s 5
	Write-host ""	
	
	ForEach($host2 in Get-Content -Path $location"\alive.txt")
	{
	$shre1 = NET.EXE VIEW $host2
		if ($shre1 -eq $null -OR $shre1 -contains "There are no entries in the list." -OR $shre1 -contains "System error 53 has occurred." -OR $shre1 -contains "The network path was not found."){
		write-host "No Shares Found On $host2" -BackgroundColor Red 
		Write-host ""
		}
		else {
		Write-host "Found Shares On $host2" -BackgroundColor Green -ForegroundColor Black
		Write-host ""
		$host2 | out-file $location"\sharesfound.txt" -Append -NoClobber 
		}
	}
	ForEach ($host3 in Get-Content -Path $location"\sharesfound.txt"){
		$shre2 = $host3 | Get-SharedFolder
		$shre2 | ft -Property ComputerName,'Share name','Type',Path -AutoSize | out-file $location"\"$filename".txt" -Append -NoClobber 
	}
Remove-Item $location"\hosts.txt"	
Remove-Item $location"\sharesfound.txt"	
}	


Write-Host " 

" 
Write-Host "Shares have been written to $location\$filename! Have Fun!" -BackgroundColor Black -ForegroundColor Green



	
