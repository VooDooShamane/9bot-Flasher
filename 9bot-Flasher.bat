:AT32DSTART
@echo off
mode 78,45
setlocal enabledelayedexpansion
set "aver=v1.0.2"
set "home=%~dp0"
cd /d "%home%\res"
set "sfk=bin\sfk.exe"
set "ocd=bin\openocd\bin\ocd+AT32_ByVooDooShamane.exe"
set /a errors=0
call :AT32DHEAD


@echo test>WritePermTest
if not exist WritePermTest (
	color 4
	@echo No writing permission in^:
	@echo.
	@echo  - %home% -
	@echo.
	@echo Please move AT32-Downgrader to C^:^\
	@echo.
	pause
	exit
	) else (
	del WritePermTest	
	)

REM -------------------------------------------------------

:AT32DSELESC
set "esc=             "
set "action=                    "
call :AT32DHEAD
@echo  Select ESC (Controller)
@echo.
@echo  1 = G30 v1.1
@echo  2 = F-Series v0.9
@echo.

choice /c 12e /n /m "Press [1],[2] or [e] to exit"
if "%ERRORLEVEL%" == "1" set "esc=G30 v1.1     "
if "%ERRORLEVEL%" == "2" set "esc=F-Series v0.9" & @echo not implemented yet & pause & goto :AT32DSELESC

if "%ERRORLEVEL%" == "3" goto :AT32DEND
if "%ERRORLEVEL%" == "255" @echo ERROR & pause & goto :AT32DSELESC

REM -------------------------------------------------------

:AT32DSELACT
set "action=                    "
call :AT32DHEAD
@echo  Select an Action
@echo.
@echo  1 = Downgrade
@echo  2 = Write Flash (clear or edit config)
@echo  3 = Backup DRV Config
@echo  4 = Dump AT32 Bootloader
@echo.

choice /c 1234b /n /m "Press [1],[2],[3],[4] or [b] for back"
if "%ERRORLEVEL%" == "1" set "action=Downgrade           " & goto :DOWNGRADE
if "%ERRORLEVEL%" == "2" set "action=Write Flash         " & @echo not implemented yet & pause & goto :AT32DSELACT
if "%ERRORLEVEL%" == "3" set "action=Backup DRV Config   " & goto :BACDRVCONF
if "%ERRORLEVEL%" == "4" set "action=Dump AT32 Bootloader" & goto :DUMPBTLDR
if "%ERRORLEVEL%" == "5" goto :AT32DSELESC
if "%ERRORLEVEL%" == "255" @echo ERROR & pause & goto :AT32DSELACT

REM -----------------------------------
REM        END OF UI PART
REM -----------------------------------

REM ------------------------Write Flash------------------------

:WRITEFLASH
REM will be implemented in next version

REM ------------------------END Write Flash------------------------

REM ------------------------Backup DRV Config------------------------

:BACDRVCONF
call :AT32DHEAD
@echo In the next step the DRV config will be dumped from the ESC's MCU RAM.
@echo.
@echo If not done already, connect ST-Link adapter to PC now.
@echo Press any key, to start the initial countdown.
@echo.
pause
@echo.
@echo Connect ST-Link wires to ESC.
@echo You have 30 seconds to do so...
@echo ^[press "s" to skip countdown^]
@echo.
set "ATsleep=30"
call :AT32DSLEEP

call :AT32DHEAD
@echo Dumping ESC^'s Config...
set "OCDiofle=RAM.bin"
set "OCDsofst=0x20000000"
set "OCDleng=0x7D00"
call :OOCDDUMP
call :FILTDRVCONF

if %ESC_MOTOR_GEN% EQU 0300 (
%sfk% tell [red]Warning^^!
@echo Gen. 4 Motor detected
@echo These new engines do only work with DRV187 firmwares and newer.
@echo.
)

@echo.
%sfk% tell [green] *DRV config Backup created*
@echo.
pause
goto :AT32DSELESC
pause

REM ------------------------END Backup DRV Config-----------------------

REM ------------------------Downgrade------------------------

:DOWNGRADE
call :AT32DHEAD
call :VERIFYFIRM
call :AT32DHEAD
@echo In the next step the automatic downgrade process will beginn.
@echo If not done already, connect ST-Link adapter to PC now.
@echo Press any key, to start the initial countdown.
@echo.
pause
@echo.
@echo Connect ST-Link wires to ESC.
@echo You have 30 seconds to do so...
@echo ^[press "s" to skip countdown^]
@echo.
set "ATsleep=30"
call :AT32DSLEEP

call :AT32DHEAD
@echo Dumping ESC^'s Config...
set "OCDiofle=RAM.bin"
set "OCDsofst=0x20000000"
set "OCDleng=0x7D00"
call :OOCDDUMP
call :FILTDRVCONF

if %ESC_MOTOR_GEN% EQU 0300 (
%sfk% tell [red]Warning^^!
@echo Gen. 4 Motor detected
@echo These new engines do only work with DRV187 firmwares and newer.
@echo Do you realy want to continue with downgrade^?
@echo.
choice /c yn /n /m "Press [y] to proceed anyways, or [n] to abort"
if "!ERRORLEVEL!" == "2" goto :AT32DEND
@echo.
)

@echo performing FLASH mass erase
call :OOCDERASE
%sfk% tell [green]Done
@echo.

@echo writing AT32 Bootloader
set "OCDiofle=firmwares/AT32_BOOTLOADER.bin"
set "OCDsofst=0x08000000"
call :OOCDWRITE
%sfk% tell [green]Done
@echo.

@echo writing DRV
set "OCDiofle=firmwares/DRV173.bin"
set "OCDsofst=0x08001000"
call :OOCDWRITE
%sfk% tell [green]Done
@echo.

@echo writing DRV_CONFIG
set "OCDiofle=DRV_CONF.bin"
set "OCDsofst=0x0801C000"
call :OOCDWRITE
%sfk% tell [green]Done
@echo.

%sfk% tell [green] *ESC successfully Downgraded*
@echo.
pause
goto :AT32DSELESC
pause


REM ------------------------END Downgrade------------------------



REM ------------------------Dump Bootloader------------------------

:DUMPBTLDR
call :AT32DHEAD
@echo You will need an vulnerable G30 v1.1 ESC
@echo with AT32 MCU running DRV173 or lower
@echo and flash my patched DRV173 Bootloader dumper to it via OTA update.
@echo After that, you can extract the Bootloader from
@echo the controller running the patched DRV173 using ST-Link.
@echo If you are lost, take a look at RollerPlausch.com.
@echo. 
@echo  1 = create patched DRV173
@echo  2 = Dump Bootloader using ST-Link
@echo.
choice /c 12b /n /m "Press [1],[2] or [b] for back"
if "%ERRORLEVEL%" == "1" goto :PATCHDRV
if "%ERRORLEVEL%" == "2" goto :GETBTLDR
if "%ERRORLEVEL%" == "3" goto :AT32DSELACT
if "%ERRORLEVEL%" == "255" @echo ERROR & pause & goto :DUMPBTLDR

REM -----Dump Bootloader Patch DRV173 Part-----

:PATCHDRV
call :AT32DHEAD

if not exist "%home%res\firmwares\DRV173.bin" (
	%sfk% tell [red]Error^^![def] No vanilla DRV173.bin found.
	@echo.
	@echo Download it first from here:
	@echo.
	@echo "https://files.scooterhacking.org/firmware/max/DRV/DRV173.bin"
	@echo.
	@echo and put it in this directory:
	@echo.
	@echo "%home%res\firmwares\DRV173.bin"
	@echo.
	pause
	goto :DUMPBTLDR
	) else (
		@echo Found DRV173
		@echo verifying md5sum
		for /f %%m in ('%sfk% md5 "%home%res\firmwares\DRV173.bin"') do if not ["%%m"] == ["7000da123a7310d90cde2a10bf2029e4"] (
					@echo.
					%sfk% tell [red]%%m
					@echo Vanilla DRV173 does not match expected md5sum
					@echo.
					pause
					goto :DUMPBTLDR
		) else (
			@echo.
			%sfk% tell [green]%%m
			@echo Vanilla DRV173 md5sum verified
			@echo.
			)
)
@echo patching DRV173.bin
copy "%home%res\firmwares\DRV173.bin" "%home%DRV173_BTLD2RAM.bin" >NUL
%sfk% replace "%home%DRV173_BTLD2RAM.bin" -binary /06494A78824202D84A78002A04D148704878024914314871704700000C00/0549064A08681060091D121D014C0C45F8D17047A00A000800000008F00B/ -yes >NUL
@echo.
%sfk% tell [green]Done^^![def] patched DRV173 created here:
@echo.
@echo "%home%DRV173_BTLD2RAM.bin"
@echo.
@echo verifying md5sum of patched DRV173

for /f %%m in ('%sfk% md5 "%home%DRV173_BTLD2RAM.bin"') do if not ["%%m"] == ["35e830b2e3562117eba1e71d3e24763e"] (
	@echo.
	%sfk% tell [red]%%m
	@echo Patched DRV173 does not match expected md5sum
	@echo.
	pause
	goto :DUMPBTLDR
	) else (
		@echo.
		%sfk% tell [green]%%m
		@echo Patched DRV173 md5sum verified
		@echo.
)

pause
goto :DUMPBTLDR

REM -----END Dump Bootloader Patch DRV173 Part-----

REM -----Dump Bootloader ST-Link Part-----

:GETBTLDR
call :AT32DHEAD
@echo In the next step the Bootloader will be dumped via ST-Link.
@echo Press any key, to start the initial countdown.
@echo If not done already, connect ST-Link adapter to PC now.
@echo.
pause
@echo.
@echo Connect ST-Link wires to ESC running the patched DRV173 now.
@echo You have 30 seconds to do so...
@echo ^[press "s" to skip countdown^]
@echo.
set "ATsleep=30"
call :AT32DSLEEP

@echo.
@echo Dumping Bootloader...
set "OCDiofle=AT32_BOOTLOADER.bin"
set "OCDsofst=0x20000BF0"
set "OCDleng=0xAA0"
call :OOCDDUMP

%sfk% tell [green]Done!
@echo.
@echo verifying md5sum of Bootloader
for /f %%m in ('%sfk% md5 "%home%res\AT32_BOOTLOADER.bin"') do if not ["%%m"] == ["d5324fa75fc3303578740ee85526811a"] (
	@echo.
	%sfk% tell [red]%%m
	@echo Bootloader does not match expected md5sum
	@echo.
	pause
	goto :DUMPBTLDR
	) else (
		@echo.
		%sfk% tell [green]%%m
		@echo Bootloader md5sum verified
		copy "AT32_BOOTLOADER.bin" "firmwares\AT32_BOOTLOADER.bin" >NUL & del "AT32_BOOTLOADER.bin" >NUL
		@echo.
)
pause
goto :AT32DSELACT

REM -----END Dump Bootloader ST-Link Part-----

REM ------------------------END Dump Bootloader------------------------

REM --------------

:OOCDINIT
%ocd% -f interface/stlink.cfg -f target/stm32f1x.cfg -c "init" -c "reset halt" -c "exit" 2>&0 2>>AT32-Downgrader.log
if errorlevel 1 (
	call :OOCDERROR %0
	goto :OOCDINIT
)
goto :eof
pause
exit

REM --------------

:OOCDERROR
set /a errors+=1
%sfk% tell [red]Error![def] ^[%errors%^/10^] can not connect to target, retry in 5 seconds
@echo ERROR %1 no Connection, %errors%^/10 >>AT32-Downgrader.log
if ["%errors%"] == ["10"] (
	@echo Errors ^[%errors%^/10^]
	@echo Error limit reached^^!
	@echo Do troubleshooting first and start again
	pause
	set /a errors=0
	goto :AT32DSTART
	)
choice /d n /t 5 >NUL
goto :eof
pause
exit

REM --------------

:OOCDDUMP
%ocd% -f "interface/stlink.cfg" -f target/stm32f1x.cfg -c "init" -c "dump_image %OCDiofle% %OCDsofst% %OCDleng%" -c "exit" 2>&0 2>>AT32-Downgrader.log
if errorlevel 1 (
	call :OOCDERROR %0
	call :OOCDINIT
	goto :OOCDDUMP
)
goto :eof
pause
exit


REM --------------

:OOCDWRITE
%ocd% -f "interface/stlink.cfg" -f target/stm32f1x.cfg -c "init" -c "reset halt" -c "program %OCDiofle% %OCDsofst% verify" -c "reset" -c "exit" 2>&0 2>>AT32-Downgrader.log
if errorlevel 1 (
	call :OOCDERROR %0
	call :OOCDINIT
	goto :OOCDWRITE
)
goto :eof
pause
exit

REM --------------

:OOCDERASE
%ocd% -f "interface/stlink.cfg" -f target/stm32f1x.cfg -c "init" -c "reset halt" -c "stm32f1x unlock 0" -c "exit" 2>&0 2>>AT32-Downgrader.log
if errorlevel 1 (
	call :OOCDERROR %0
	call :OOCDINIT
	goto :OOCDERASE
)
goto :eof
pause
exit

REM --------------

:AT32DEND
@echo exiting now
pause
exit

REM ---------------------------------------------------

:AT32DSLEEP
if not "%ATsleep%" == "0" (
	for /f %%m in ('set /a "a=%ATsleep% %% 5"') do if not %%m EQU 0 (
		@echo|set /p="."
	) else (
		@echo|set /p="%ATsleep%"
	)
	
	choice /c gs /d g /t 1 >NUL
	if errorlevel 2 goto :eof
	set /a ATsleep-=1
	goto :AT32DSLEEP
)
@echo 0
goto :eof

REM ---------------------------------------------------

:9BOTCRAPLE2DEC
set INP=%1
for /f %%g in ('%sfk% num -hex -show hexle %INP%') do set INP_LE=%%g >NUL
@set INP_LE=%INP_LE:~0,4%
@set INP_LE_3=%INP_LE:~-1,1%
@set INP_LE_2=%INP_LE:~-2,1%
@set INP_LE_1=%INP_LE:~-3,1%
if 0x%INP_LE_3% GTR 10 (
	set /a INP_temp=0x%INP_LE_3% + %INP_LE_2%0
	set OUTP_DEC=%INP_LE_1%!INP_temp!
	) else (
		set OUTP_DEC=%INP_LE_1%%INP_LE_2%%INP_LE_3%
)
goto :eof

REM ---------------------------------------------------

:VERIFYFIRM
call :AT32DHEAD
if not exist "%home%res\firmwares\AT32_BOOTLOADER.bin" (
	%sfk% tell [red]Error^^![def] No AT32 Bootloader found
	@echo.
	@echo Dump Bootloader first from an vulnerable ESC.
	@echo Use the inbuild dump function,
	@echo or put it manualy this directory:
	@echo.
	@echo "%home%res\firmwares\AT32_BOOTLOADER.bin"
	@echo.
	pause
	goto :AT32DSELACT
	) else (
		@echo Found AT32 Bootloader
		@echo verifying md5sum
		for /f %%m in ('%sfk% md5 "%home%res\firmwares\AT32_BOOTLOADER.bin"') do if not ["%%m"] == ["d5324fa75fc3303578740ee85526811a"] (
					@echo.
					%sfk% tell [red]%%m
					@echo AT32_BOOTLOADER.bin does not match expected md5sum
					@echo.
					pause
					goto :AT32DSELACT
		) else (
			@echo.
			%sfk% tell [green]%%m
			@echo AT32_BOOTLOADER.bin md5sum verified
			@echo.
			)
)

if not exist "%home%res\firmwares\DRV173.bin" (
	%sfk% tell [red]Error^^![def] No vanilla DRV173.bin found.
	@echo.
	@echo Download it first from here:
	@echo.
	@echo "https://files.scooterhacking.org/firmware/max/DRV/DRV173.bin"
	@echo.
	@echo and put it in this directory:
	@echo.
	@echo "%home%res\firmwares\DRV173.bin"
	@echo.
	pause
	goto :AT32DSELACT
	) else (
		@echo Found DRV173
		@echo verifying md5sum
		for /f %%m in ('%sfk% md5 "%home%res\firmwares\DRV173.bin"') do if not ["%%m"] == ["7000da123a7310d90cde2a10bf2029e4"] (
					@echo.
					%sfk% tell [red]%%m
					@echo Vanilla DRV173 does not match expected md5sum
					@echo.
					pause
					goto :AT32DSELACT
		) else (
			@echo.
			%sfk% tell [green]%%m
			@echo Vanilla DRV173.bin md5sum verified
			@echo.
			)
)

choice /c gs /d g /t 3 >NUL
goto :eof

REM ---------------------------------------------------

:FILTDRVCONF
for /f %%f in ('%sfk% xhexfind "RAM.bin" "/\x5c\x51/" +filt -+0x "-line=4" -replace "_RAM.bin : hit at offset __" -replace "_ len 2__"') do set ramconfof=%%f
%sfk% partcopy "%home%res\RAM.bin" %ramconfof% 0x200 "%home%res\DRV_CONF.bin" -yes >NUL
%sfk% tell [green]Done

for /f %%h in ('%sfk% hexdump -nofile -flat -offlen 0x00000020 0x0000000E "%home%res\DRV_CONF.bin"') do set "ESC_SN=%%h" >NUL
for /f %%h in ('%sfk% hexdump -nofile -pure -offlen 0x000001B4 0x0000000C "%home%res\DRV_CONF.bin"') do set ESC_UUID=%%h >NUL
for /f %%h in ('%sfk% hexdump -nofile -pure -offlen 0x00000034 0x00000002 "%home%res\DRV_CONF.bin"') do set ESC_DRV=%%h >NUL
call :9BOTCRAPLE2DEC %ESC_DRV%
set ESC_DRV_DEC=!OUTP_DEC!
for /f %%h in ('%sfk% hexdump -nofile -pure -offlen 0x00000052 0x00000004 "%home%res\DRV_CONF.bin"') do set ESC_tmile=%%h >NUL
for /f %%g in ('%sfk% num -hex -show hexle %ESC_tmile%') do set /a ESC_tmile_UI=0x%%g / 1000 >NUL
for /f %%h in ('%sfk% hexdump -nofile -pure -offlen 0x00000064 0x00000004 "%home%res\DRV_CONF.bin"') do set ESC_trunt=%%h >NUL
for /f %%g in ('%sfk% num -hex -show hexle %ESC_trunt%') do set /a ESC_trunt_UI=0x%%g / 60 / 60 >NUL
for /f %%h in ('%sfk% hexdump -nofile -pure -offlen 0x000000FE 0x00000002 "%home%res\DRV_CONF.bin"') do set ESC_MOTOR_GEN=%%h >NUL
for /f %%h in ('%sfk% hexdump -nofile -pure -offlen 0x000000CE 0x00000002 "%home%res\DRV_CONF.bin"') do set ESC_BMS=%%h >NUL
call :9BOTCRAPLE2DEC %ESC_BMS%
set ESC_BMS_DEC=!OUTP_DEC!
for /f %%h in ('%sfk% hexdump -nofile -pure -offlen 0x000000D0 0x00000002 "%home%res\DRV_CONF.bin"') do set ESC_BLE=%%h >NUL
call :9BOTCRAPLE2DEC %ESC_BLE%
set ESC_BLE_DEC=!OUTP_DEC!
for /f %%h in ('%sfk% hexdump -nofile -pure -offlen 0x0000003A 0x00000002 "%home%res\DRV_CONF.bin"') do set ESC_STAT=%%h >NUL
if %ESC_STAT% EQU 0008 (
	set ESC_STAT_UI=Activated
	) else (
		set ESC_STAT_UI=%ESC_STAT%
)

call :AT32CHEAD
@echo Dumping ESC^'s Config...
%sfk% tell [green]Done

if not exist DRV_Configs\ESC-%ESC_UUID:~0,24%\NUL (
mkdir DRV_Configs\ESC-%ESC_UUID:~0,24%\ >NUL
)
copy /b /y "DRV_CONF.bin" "DRV_Configs\ESC-%ESC_UUID:~0,24%\DRV_CONF.bin" >NUL
copy /b /y "RAM.bin" "DRV_Configs\ESC-%ESC_UUID:~0,24%\RAM.bin" >NUL

@echo -------------------------------------------------- >DRV_Configs\ESC-%ESC_UUID:~0,24%\DRV_CONF_INFO.txt
@echo. >>DRV_Configs\ESC-%ESC_UUID:~0,24%\DRV_CONF_INFO.txt
@echo SerialNr       : %ESC_SN% >>DRV_Configs\ESC-%ESC_UUID:~0,24%\DRV_CONF_INFO.txt
@echo UUID           : %ESC_UUID% >>DRV_Configs\ESC-%ESC_UUID:~0,24%\DRV_CONF_INFO.txt
@echo Status         : %ESC_STAT_UI% >>DRV_Configs\ESC-%ESC_UUID:~0,24%\DRV_CONF_INFO.txt
@echo Motor gen.     : %ESC_MOTOR_GEN% >>DRV_Configs\ESC-%ESC_UUID:~0,24%\DRV_CONF_INFO.txt
@echo DRV version    : %ESC_DRV_DEC% >>DRV_Configs\ESC-%ESC_UUID:~0,24%\DRV_CONF_INFO.txt
@echo BLE version    : %ESC_BLE_DEC% >>DRV_Configs\ESC-%ESC_UUID:~0,24%\DRV_CONF_INFO.txt
@echo BMS version    : %ESC_BMS_DEC% >>DRV_Configs\ESC-%ESC_UUID:~0,24%\DRV_CONF_INFO.txt
@echo Total mileage  : %ESC_tmile_UI% km >>DRV_Configs\ESC-%ESC_UUID:~0,24%\DRV_CONF_INFO.txt
@echo Total run time : %ESC_trunt_UI% hour >>DRV_Configs\ESC-%ESC_UUID:~0,24%\DRV_CONF_INFO.txt
@echo. >>DRV_Configs\ESC-%ESC_UUID:~0,24%\DRV_CONF_INFO.txt
@echo -------------------------------------------------- >>DRV_Configs\ESC-%ESC_UUID:~0,24%\DRV_CONF_INFO.txt

@echo.
@echo ESC's config safed to: 
@echo res\DRV_Configs\ESC-%ESC_UUID:~0,24%\
@echo.
goto :eof

REM ------------------------9bot---------------------------

:AT32DHEAD
cls
@echo.
@echo  ****************************************************************************
@echo  # -MAIN MENUE- #
@echo  ****************
@echo.
@echo         ____  __          __        ________           __             
@echo        / __ \/ /_  ____  / /_      / ____/ /___ ______/ /_  ___  _____
@echo       / /_/ / __ \/ __ \/ __/_____/ /_  / / __ `/ ___/ __ \/ _ \/ ___/
@echo       \__, / /_/ / /_/ / /_/_____/ __/ / / /_/ (__  ) / / /  __/ /    
@echo      /____/_.___/\____/\__/     /_/   /_/\__,_/____/_/ /_/\___/_/ %aver%   
@echo                         powered by OpenOCD                             
@echo                         created by VooDooShamane                         
@echo                         support Rollerplausch.com                        
@echo.                                                                 
@echo.
@echo  ******************************             *********************************
@echo  # Controller = %esc% #             # Action = %action% #
@echo  ****************************************************************************
@echo.
goto :eof
pause
exit

REM ------------------------9bot---------------------------

:AT32CHEAD
cls
@echo.
@echo  ****************************************************************************
@echo  # -DRV CONFIG- #                       9bot-Flasher %aver% by VooDooShamane
@echo  ****************
@echo.
@echo                SerialNr       : %ESC_SN%
@echo                UUID           : %ESC_UUID%
@echo                Status         : %ESC_STAT_UI%
@echo                Motor gen.     : %ESC_MOTOR_GEN%
@echo                DRV version    : %ESC_DRV_DEC%
@echo                BLE version    : %ESC_BLE_DEC%
@echo                BMS version    : %ESC_BMS_DEC%
@echo                Total mileage  : %ESC_tmile_UI% km
@echo                Total run time : %ESC_trunt_UI% h
@echo.                                                                 
@echo  ******************************             *********************************
@echo  # Controller = %esc% #             # Action = %action% #
@echo  ****************************************************************************
@echo.
goto :eof
pause
exit

REM ------------------------9bot---------------------------



