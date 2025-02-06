::[Bat To Exe Converter]
::
::YAwzoRdxOk+EWAjk
::fBw5plQjdCyDJGyX8VAjFC9bQAODAE+/Fb4I5/jH/+KItkIiBrJtLcKLi/nfcd9Cvwi0Jtt+gzRTm8Rs
::YAwzuBVtJxjWCl3EqQJgSA==
::ZR4luwNxJguZRRnk
::Yhs/ulQjdF+5
::cxAkpRVqdFKZSDk=
::cBs/ulQjdF+5
::ZR41oxFsdFKZSDk=
::eBoioBt6dFKZSDk=
::cRo6pxp7LAbNWATEpCI=
::egkzugNsPRvcWATEpCI=
::dAsiuh18IRvcCxnZtBJQ
::cRYluBh/LU+EWAjk
::YxY4rhs+aU+JeA==
::cxY6rQJ7JhzQF1fEqQJQ
::ZQ05rAF9IBncCkqN+0xwdVs0
::ZQ05rAF9IAHYFVzEqQJQ
::eg0/rx1wNQPfEVWB+kM9LVsJDGQ=
::fBEirQZwNQPfEVWB+kM9LVsJDGQ=
::cRolqwZ3JBvQF1fEqQJQ
::dhA7uBVwLU+EWDk=
::YQ03rBFzNR3SWATElA==
::dhAmsQZ3MwfNWATElA==
::ZQ0/vhVqMQ3MEVWAtB9wSA==
::Zg8zqx1/OA3MEVWAtB9wSA==
::dhA7pRFwIByZRRnk
::Zh4grVQjdCyDJGyX8VAjFC9bQAODAE+/Fb4I5/jHzOaIrEQed/cta4DJ85DAJfgWig==
::YB416Ek+ZW8=
::
::
::978f952a14a936cc963da21a135fa983
@echo off
title ClonicGlobal
color 0a
mode con: cols=120 lines=30
setlocal EnableDelayedExpansion

:: Basit bir kendini koruma
if not "%~n0"=="change_windows_device_id" exit /b
if not "%~x0"==".bat" exit /b

:: Yönetici hakları kontrolü
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Bu script'i yönetici olarak çalıştırmalısınız!
    echo Lütfen script'e sağ tıklayıp "Yönetici olarak çalıştır" seçeneğini kullanın.
    pause
    exit /b 1
)

:: Güvenlik uyarısı
echo UYARI: Bu işlem sistem Device ID'nizi değiştirecek.
echo Devam etmeden önce:
echo - Tüm uygulamaları kapatın
echo - Açık işlerinizi kaydedin
echo - Antivirüs yazılımını geçici olarak devre dışı bırakın
echo.
choice /C YN /M "Devam etmek istiyor musunuz"
if %errorlevel% neq 1 exit /b

:: Rastgele hex karakterleri için dizi
set "hex=0123456789ABCDEF"

:: MachineGUID için yeni değer oluştur
set "newGUID="
for /L %%i in (1,1,32) do (
    set /a "rand=!random! %% 16"
    for %%j in (!rand!) do set "newGUID=!newGUID!!hex:~%%j,1!"
)

:: 8-4-4-4-12 formatında ayır
set "formattedGUID=%newGUID:~0,8%-%newGUID:~8,4%-%newGUID:~12,4%-%newGUID:~16,4%-%newGUID:~20,12%"

:: Yedekleme klasörü oluştur
set "BACKUP_DIR=%USERPROFILE%\Desktop\DeviceID_Backup_%date:~-4,4%%date:~-7,2%%date:~-10,2%"
mkdir "%BACKUP_DIR%" 2>nul

echo Mevcut ayarlar yedekleniyor...
reg export HKLM\SOFTWARE\Microsoft\Cryptography "%BACKUP_DIR%\Cryptography.reg" /y
reg export "HKLM\SYSTEM\CurrentControlSet\Control\IDConfigDB\Hardware Profiles\0001" "%BACKUP_DIR%\HWProfile.reg" /y

echo.
echo Yeni Device ID oluşturuluyor: %formattedGUID%
echo.

:: Kritik servisleri durdur
echo Servisler durduruluyor...
set "SERVICES=winmgmt Audiosrv AudioEndpointBuilder spooler TokenBroker WpnService"
for %%s in (%SERVICES%) do (
    net stop %%s /y >nul 2>&1
    if !errorlevel! neq 0 echo %%s servisi durdurulamadı
)

:: Registry değişiklikleri
echo Registry değişiklikleri yapılıyor...
reg add "HKLM\SOFTWARE\Microsoft\Cryptography" /v MachineGuid /t REG_SZ /d "%formattedGUID%" /f
if %errorlevel% neq 0 goto :error

reg add "HKLM\SYSTEM\CurrentControlSet\Control\IDConfigDB\Hardware Profiles\0001" /v HwProfileGuid /t REG_SZ /d "{%formattedGUID%}" /f
if %errorlevel% neq 0 goto :error

:: Sistem önbelleğini temizle
echo Sistem önbelleği temizleniyor...
echo y | rmdir /s "%SYSTEMDRIVE%\Windows\System32\DriverStore\FileRepository" 2>nul
echo y | rmdir /s "C:\ProgramData\Microsoft\Windows\DeviceMetadataCache" 2>nul
del /f /q "%SYSTEMDRIVE%\Windows\INF\*.PNF" 2>nul

:: WMI repository'yi yeniden oluştur
echo WMI repository yeniden oluşturuluyor...
cd /d %windir%\system32\wbem
for %%i in (*.dll) do (
    regsvr32 /s %%i
    if !errorlevel! neq 0 echo %%i kaydedilemedi
)
winmgmt /resetrepository
if %errorlevel% neq 0 echo WMI repository sıfırlanamadı

:: Servisleri yeniden başlat
echo Servisler yeniden başlatılıyor...
for %%s in (%SERVICES%) do (
    net start %%s >nul 2>&1
    if !errorlevel! neq 0 echo %%s servisi başlatılamadı
)

:: Sistem önbelleğini temizle
echo Son temizlik yapılıyor...
ipconfig /flushdns >nul 2>&1
wsreset >nul 2>&1
netsh winsock reset >nul 2>&1

echo.
echo İşlem başarıyla tamamlandı!
echo Yeni Device ID: %formattedGUID%
echo.
echo Yedekler şu klasöre kaydedildi: %BACKUP_DIR%
echo.
goto :end

:error
echo.
echo HATA: İşlem sırasında bir sorun oluştu!
echo Yedekler kullanılarak sistem geri yüklenecek...
reg import "%BACKUP_DIR%\Cryptography.reg"
reg import "%BACKUP_DIR%\HWProfile.reg"

:: Servisleri yeniden başlatmayı dene
for %%s in (%SERVICES%) do net start %%s >nul 2>&1

:end
echo.
echo Herhangi bir sorun yaşarsanız, yedek dosyalarını kullanarak geri yükleme yapabilirsiniz:
echo %BACKUP_DIR%
pause 