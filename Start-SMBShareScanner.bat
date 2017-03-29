<<<<<<< HEAD
Echo OFF
set /P Domain=Enter Domain:
set /P Usern=Enter Username:
 
runas /user:%Domain%\%Usern% " powershell -nologo -noprofile -noexit  -Command '%~dp0SMBShareScanner.ps1'

cls
=======
Echo OFF
set /P Domain=Enter Domain:
set /P Usern=Enter Username:
 
runas /user:%Domain%\%Usern% " powershell -nologo -noprofile -noexit  -Command '%~dp0SMBShareScanner.ps1'

cls
>>>>>>> 6577e8c9ed0db5c2060cf857961cd0bfb99eeda5
exit