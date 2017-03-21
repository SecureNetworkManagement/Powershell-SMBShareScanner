ECHO OFF 
set /P Usern=Enter Username:
set userrunas=runas /user:<Domain>\%Usern% " 

%userrunas%SMBShareScanner.ps1