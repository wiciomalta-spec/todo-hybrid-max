cd "C:\Users\User\Desktop\todo-hybrid-max\Watchdog"
dotnet publish -c Release

$exe = "C:\Users\User\Desktop\todo-hybrid-max\Watchdog\bin\Release\net10.0\publish\Watchdog.exe"

sc.exe delete WatchdogService 2>$null
sc.exe create WatchdogService binPath= "$exe" start= auto
sc.exe start WatchdogService
