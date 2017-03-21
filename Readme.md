SMBShareScanner.ps1

This PowerShell script will allow you to scan open shares based on a list you provide or a subnet you enter. It will process hostnames or IP addresses and attempt to connect to the shares on a machine using WMI to make the connection.

Usage C:> SMBShareScanner.ps1

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
   
Start-SMBShareScanner.bat

This is a simple batch script wrapper for a runas command for when you share your script with someone who can't right click and choose runas ... Seriously, we had to do this for a 'Sys Admin'