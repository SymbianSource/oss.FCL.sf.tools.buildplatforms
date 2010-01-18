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
echo ===-------------------------------------------------
echo === Stage=1
echo ===-------------------------------------------------
perl -le "$time=localtime; print '=== Stage=1 started ', $time"
perl -le "$time=localtime; print '=== Stage=1 S60_build.cmd started', $time"

echo Build S60 
echo usage:   S60_build.cmd
echo example: S60_build.cmd

if not defined LOGS_PATH (
call set LOGS_PATH=\logs\
)

if not defined ZIPS_PATH (
call set ZIPS_PATH=\zips\
)

if not exist %LOGS_PATH% (
md %LOGS_PATH%
)
if not exist %ZIPS_PATH% (
md %ZIPS_PATH%
)


perl -le "$time=localtime; print '=== Stage=1 S60_build.cmd started', $time"
call vcvars32
call set copycmd=/y


perl -le "$time=localtime; print '=== Stage=1 touch to s60 started ', $time"
call toucher.exe \sf
call toucher.exe \ext

perl -le "$time=localtime; print '=== Stage=1 attrib -r started', $time"
call  attrib -r /s \epoc32\*
call  attrib -r /s \ext\*
call  attrib -r /s \sf\*


cd\
perl -le "$time=localtime; print '=== Stage=1 Build started', $time"
echo Building ...
call \epoc32\tools\s60tools\build_tbs.cmd S60Build \epoc32\tools\s60tools\
echo Build end

perl -le "$time=localtime; print '=== Stage=1 bldmelast started', $time"
call \epoc32\tools\s60tools\build_tbs.cmd bldmelast \epoc32\tools\s60tools\

call cmd /c "cd \config\s60_52_config && cmaker config_post_task ACTION=export BUILD=oem S60=52"
perl -le "$time=localtime; print '=== Stage=1 zip western delta binaries', $time"
call perl \epoc32\tools\s60tools\parse_what_log.pl -i %LOGS_PATH%bldmelast_bld.log -filter \epoc32 -zip %ZIPS_PATH%delta_western_package -ex productvariant.hrh

perl -le "$time=localtime; print '=== Stage=1 scanlog_html started', $time"
call perl \epoc32\tools\htmlscanlog.pl -l %LOGS_PATH%s60Build_bld.log -l %LOGS_PATH%bldmelast_bld.log -o %LOGS_PATH%scanlog_s60Build_full.html -v

perl -le "$time=localtime; print '=== Stage=1 finished ', $time"

endlocal