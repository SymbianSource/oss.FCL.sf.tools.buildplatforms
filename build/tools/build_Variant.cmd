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
if not defined ZIPS_PATH (
call set ZIPS_PATH=\zips\
)

if not defined LOGS_PATH (
call set LOGS_PATH=\logs\
)

echo set build tools path
PATH=%PATH%;\epoc32\tools\;\epoc32\tools\build\;\epoc32\tools\s60tools\

if not exist %ZIPS_PATH% (
md %ZIPS_PATH%
)
if not exist %LOGS_PATH% (
md %LOGS_PATH%
)

if exist \epoc32\tools\s60tools\variant_build_china.xml (
perl -le "$time=localtime; print '=== Stage=1 build china variant', $time"
rem generate apac cenreps with new config tool 
cd \s60\tools\toolsextensions\ConfigurationTool\
call cli_build.cmd -master_conf apac -impl \epoc32\rom\config\confml_data\s60 -confml \epoc32\rom\config\confml_data\apac -report \logs\configtool_apac_delta.txt -ignore_errors > %LOGS_PATH%configtool_apac_log.txt 2>&1
cd \
call build_tbs.cmd variant_build_china \epoc32\tools\s60tools\

perl -le "$time=localtime; print '=== Stage=1 zip china delta binaries', $time"
call perl \epoc32\tools\s60tools\parse_what_log.pl -i %LOGS_PATH%variant_build_china_bld.log -filter \epoc32 -zip %ZIPS_PATH%delta_china_package -o %LOGS_PATH%variant_china_what.log -ex productvariant.hrh

call zip  -r -u   %ZIPS_PATH%delta_china_package -@ < \logs\configtool_apac_delta.txt 

)

if exist \epoc32\tools\s60tools\variant_build_japan.xml (
perl -le "$time=localtime; print '=== Stage=1 build japan variant', $time"
cd \s60\tools\toolsextensions\ConfigurationTool\
call cli_build.cmd -master_conf japan -impl \epoc32\rom\config\confml_data\s60 -confml \epoc32\rom\config\confml_data\japan -report \logs\configtool_japan_delta.txt -ignore_errors > %LOGS_PATH%configtool_japan_log.txt 2>&1
cd \
call build_tbs.cmd variant_build_japan \epoc32\tools\s60tools\

perl -le "$time=localtime; print '=== Stage=1 zip japan delta binaries', $time"
call perl \epoc32\tools\s60tools\parse_what_log.pl -i %LOGS_PATH%variant_build_japan_bld.log -filter \epoc32 -zip %ZIPS_PATH%delta_japan_package -o %LOGS_PATH%variant_japan_what.log -ex productvariant.hrh

call zip  -r -u   %ZIPS_PATH%delta_japan_package -@ < \logs\configtool_japan_delta.txt

)

cd \s60\tools\toolsextensions\ConfigurationTool\
rem thai
perl -le "$time=localtime; print '=== Stage=1 zip thai delta binaries', $time"
call cli_build.cmd -master_conf thai -impl \epoc32\rom\config\confml_data\s60 -confml \epoc32\rom\config\confml_data\thai -report \logs\configtool_thai_delta.txt -ignore_errors > %LOGS_PATH%configtool_thai_log.txt 2>&1
call zip  -r      %ZIPS_PATH%delta_thai_package -@ < \logs\configtool_thai_delta.txt

rem return western 
cd \s60\tools\toolsextensions\ConfigurationTool\
call cli_build.cmd -master_conf s60 -impl \epoc32\rom\config\confml_data\s60 -confml \epoc32\rom\config\confml_data\s60 -report \logs\configtool_return_western.txt -ignore_errors > %LOGS_PATH%cf_return_western_log.txt 2>&1
call zip  -r -u   %ZIPS_PATH%delta_western_package -@ < \logs\configtool_return_western.txt
cd \
goto end

:end
endlocal
