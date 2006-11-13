rem Build.bat for Windows builds
mkdir %temp%\ledger-smb-build
mkdir %temp%\ledger-smb-build\perl
mkdir %temp%\ledger-smb-build\ledger-smb
mkdir %temp%\ledger-smb-build\postgresql
mkdir %temp%\ledger-smb-build\apache

rem copy files
xcopy c:\vanilla-perl %temp%\ledger-smb-build\perl
xcopy ..\.. %temp%\ledger-smb-build\ledger-smb
xcopy "c:\Program Files\PostgreSQL\8.1\" %temp%\ledger-smb-build\postgresql
xcopy path\to\apache %temp%\ledger-smb-build\apache

rem TODO: generate wix files

rem TODO:  run wix

rem TODO:  package
