<# 
.Synopsis 
   Query share information including connection numbers 
.DESCRIPTION 
   Returns the number of connections to Shares on local or remote systems and the share information 
.EXAMPLE 
   Get-ShareInfo -ComputerName Server1,Server2 | Format-Table -AutoSize 
.EXAMPLE 
   Get-ShareInfo -CN Localhost 
.INPUTS 
   A String or Array of ComputerNames 
.OUTPUTS 
   An OBJECT with the following properties is returned from this function 
   PSComputerName,Name,Path,Description,Connections,MaximumAllowed,AllowMaximum 
   You could check gwmi -class win32_Share | Get-Member and add extra properties if you like 
.NOTES 
   General 
.FUNCTIONALITY 
   Using WMI to query the number of open connections to Shares on local or remote systems 
   Then adding this information to the basic win32_share info 
#> 
function Get-ShareInfo 
{ 
    Param 
    ( 
        # param1 help description 
        [Parameter(Mandatory=$true,  
                   ValueFromPipeline=$true, 
                   ValueFromPipelineByPropertyName=$true,  
                   ValueFromRemainingArguments=$false,  
                   Position=0)] 
        [Alias("cn")]  
        [String[]]$ComputerName 
    ) 
 
    Begin 
    { 
    } 
    Process 
    { 
        $ComputerName | ForEach-Object { 
           $Computer = $_ 
           try { 
                 # Connect to each computer and get the active connections on the shares 
                 $Conns = Get-WmiObject -Class Win32_ConnectionShare -Namespace root\cimv2 -ComputerName $Computer -EA Stop |  
                    Group-Object Antecedent | 
                    Select-Object @{Name="ComputerName";Expression={$Computer}}, 
                                  @{Name="Share"       ;Expression={(($_.Name -split "=") |  
                                        Select-Object -Index 1).trim('"')}}, 
                                  @{Name="Connections" ;Expression={$_.Count}} 
 
                   # Connect to each computer and get the win32_share information (for all shares) 
                   # Then add the connection details to those with connections. 
                   try { 
                            Get-WmiObject -Class Win32_Share -Namespace root\cimv2 -ComputerName $Computer -EA Stop | 
                                ForEach-Object { 
                                        $ShareInfo = $_ 
                                        $Conns | ForEach-Object { 
                                            if ($_.Share -eq $ShareInfo.Name) 
                                                { 
                                                    $ShareInfo | Add-Member -MemberType NoteProperty -Name Connections -Value $_.Connections -Force 
                                                } 
 
                                            }#Foreach-Object($Conns)  
 
                                        if (!$ShareInfo.Connections) 
                                            { 
                                                $ShareInfo | Add-Member -MemberType NoteProperty -Name Connections -Value 0    
                                            } 
 
                                        $ShareInfo | Select PSComputerName,Name,Path,Description
 
                                    }#Foreach-Object(Share)  
                       } 
                   catch 
                       { 
                            Write-Host "Cannot connect to $Computer" -BackgroundColor White -ForegroundColor Red 
                            Break 
                       } 
               } 
           catch  
               { 
                    Write-Host "Cannot connect to $Computer" -BackgroundColor White -ForegroundColor Red 
               } 
                       
 
           }#ForEach-Object(Computer) 
    } 
    End 
    { 
    } 
} 
<# 
  .SYNOPSIS  
    Get the IP addresses in a range 
  .EXAMPLE 
   Get-IPrange -start 192.168.8.2 -end 192.168.8.20 
  .EXAMPLE 
   Get-IPrange -ip 192.168.8.2 -mask 255.255.255.0 
  .EXAMPLE 
   Get-IPrange -ip 192.168.8.3 -cidr 24 
#> 
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
#$user = Read-Host = "Enter Username "
#$pass = Read-Host = "Enter pass " 
#Start-Process powershell.exe -Credential ""
Write-host 'This will allow you to scan systems for open shares on the network either with a file or cidr notation' -BackgroundColor Black -ForegroundColor Green
$main = Read-Host -Prompt 'Enter cidr or file: ' 
#$network = Read-Host -Prompt 'Enter network address:' 
#$cidr = Read-Host -Prompt "Enter CIDR : "
#$shares = Read-Host -Prompt 'Enter Location of file with IPs or Hostnames '
#$location = Read-Host -Prompt 'Enter Location you wan to save the output to '
$location = Read-Host -Prompt 'Enter Location you want to save the output to ' 

If ($main -eq 'file'){
    $shares = Read-Host -Prompt 'Enter Location of file with IPs or Hostnames ' 
    ForEach ($system in Get-Content $shares)
    {
    Get-ShareInfo $system | FT -AutoSize | out-file $location -Append -NoClobber 
    }
}
If ($main -eq 'cidr'){
    Write-Host 'You will be propmted to enter the network address and cidr notation seperately!!!!' -BackgroundColor White -ForegroundColor Red 
    $network = Read-Host -Prompt 'Enter network host address'
    $cidr = Read-Host -Prompt 'Enter CIDR' 
    Get-IPrange -ip $network -cidr $cidr | Out-file ./hosts.txt -Append -NoClobber 
        ForEach ($host1 in Get-Content -Path ./hosts.txt)
        {
        Get-ShareInfo $host1 | FT -AutoSize | out-file $location -Append -NoClobber
        Write-Host 'cidr'
        }
    Remove-Item ./hosts.txt     
    
    
}

