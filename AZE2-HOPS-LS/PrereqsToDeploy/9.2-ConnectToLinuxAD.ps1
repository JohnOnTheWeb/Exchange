iwr -Uri https://github.com/PowerShell/Win32-OpenSSH/releases/download/v0.0.22.0/OpenSSH-Win32.zip -OutFile $home\downloads/OpenSSH-Win32.zip
dir op* | Unblock-File
Expand-Archive -Path $home\downloads\OpenSSH-Win32.zip -DestinationPath $home\downloads
cd $home\downloads\OpenSSH-Win32\
ssh admin@10.144.133.70
ssh -l admin@contoso.local 10.144.133.70