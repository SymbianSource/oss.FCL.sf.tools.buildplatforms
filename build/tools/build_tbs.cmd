@echo off
rem
rem Copyright (c) 2009 Nokia Corporation and/or its subsidiary(-ies).
rem All rights reserved.
rem This component and the accompanying materials are made available
rem under the terms of "Eclipse Public License v1.0"
rem which accompanies this distribution, and is available
rem at the URL "http://www.eclipse.org/legal/epl-v10.html".
rem
rem Initial Contributors:
rem Nokia Corporation - initial contribution.
rem
rem Contributors:
rem
rem Description:
rem
@echo on

@echo off
setlocal
echo build_tbs
echo usage:   build_tbs.cmd "input xml file without extension" ["inputfile path"]
echo usage:   inputfile path is optional cases that command launch different path as inputfile
echo example: build_tbs.cmd S60Build \epoc32\tools\s60tools\
echo example: build_tbs.cmd S60Build

echo set build tools path
PATH=%PATH%;\epoc32\tools\s60tools\

rem set port 1971 for TBS by default 
if not defined TBS_PORT (
call set TBS_PORT=1971
)

rem set 2 processor by default
if not defined NUMBER_OF_PROCESSORS (
call set NUMBER_OF_PROCESSORS=2
)

rem Starts NUMBER_OF_PROCESSORS*2 clients. If NUMBER_OF_PROCESSORS is set to "0" start one client
if "%NUMBER_OF_PROCESSORS%" equ "0" (
call set /a LOOP=1
) else (
call set /a LOOP=%NUMBER_OF_PROCESSORS%*2
)
echo start clients
:loopagain
call set /a LOOP-=1
call start cmd /C "\epoc32\tools\build\buildclient.pl -w 5 -c Client%LOOP% -d localhost:%TBS_PORT% -e 1"
perl -le "sleep 1"
if not "%LOOP%" equ "0" goto :loopagain

echo delete old build log
if exist %LOGS_PATH%scanlog_%1.html (
call del /q %LOGS_PATH%scanlog_%1.html
)
echo start build server
call perl \epoc32\tools\build\buildserver.pl -p %TBS_PORT% -d %2%1.xml -l %LOGS_PATH%%1_bld.log

call perl \epoc32\tools\htmlscanlog.pl -l %LOGS_PATH%%1_bld.log -o %LOGS_PATH%scanlog_%1.html -v

endlocal



