@rem
@rem Copyright (c) 2009 Nokia Corporation and/or its subsidiary(-ies).
@rem All rights reserved.
@rem This component and the accompanying materials are made available
@rem under the terms of "Eclipse Public License v1.0"
@rem which accompanies this distribution, and is available
@rem at the URL "http://www.eclipse.org/legal/epl-v10.html".
@rem
@rem Initial Contributors:
@rem Nokia Corporation - initial contribution.
@rem
@rem Contributors:
@rem
@rem Description:
@rem
@echo off
setlocal
echo ===-------------------------------------------------
echo === Stage=1
echo ===-------------------------------------------------
perl -le "$time=localtime; print '=== Stage=1 started ', $time"
perl -le "$time=localtime; print '=== Stage=1 build_preparation.cmd started', $time"

echo Set tools and input files for build S60_5_0
echo !!! Note: Symbian genxml and htmlscanlog tools have to found from environment !!!
echo usage (all parameters are optional) :
echo build_preparation.cmd S60_build_configuration -p platform -f conf_filter
echo -p platform    : 'S60' by default , 'OSExt' is supported by S60
echo -f conf_filter : not used by default, 'nonjava' 'touch' 'no_stubs' 'no_binonly' 
echo                  are supported by S60
echo using parameter '-f' all configurations are updated 
echo in S60_SystemBuild.xml by add_build_definition_filter.pl
echo !!! NOTE parameters are case sensitive !!!

:loop
if "%1"=="" goto end_loop

if "%1" == "-f" (
set SYSTEM_CONFIGURATION_FILTER=%SYSTEM_CONFIGURATION_FILTER% %1 %2
shift
shift
goto loop
)

if "%1" == "-p" (
set BUILD_PLATFORM=%2
shift
shift
goto loop
)

if not "%1" == "" (
set S60_BUILD_CONFIGURATION=%1
)

shift
goto loop

:end_loop

if defined S60_BUILD_CONFIGURATION (if "%S60_BUILD_CONFIGURATION%" == "OSExt" (
	set BUILD_PLATFORM=OSExt
	set CMAKER_BUILD=os_prebuild
))

if not defined BUILD_PLATFORM (
	set BUILD_PLATFORM=S60
	set CMAKER_BUILD=s60_prebuild
)

if not defined S60_BUILD_CONFIGURATION (
	set S60_BUILD_CONFIGURATION=%BUILD_PLATFORM%_clean
)

echo create folder for logs
if not defined LOGS_PATH (
	set LOGS_PATH=\logs\
)

if not exist %LOGS_PATH% (
md %LOGS_PATH%
)

echo Build platform '%BUILD_PLATFORM%'
echo Build configuration '%S60_BUILD_CONFIGURATION%'
echo Used system configuration filters '%SYSTEM_CONFIGURATION_FILTER%'



if defined SYSTEM_CONFIGURATION_FILTER (
echo Add filter '%SYSTEM_CONFIGURATION_FILTER%' for all configurations in S60_SystemBuild.xml
call \sf\tools\buildplatforms\build\tools\add_build_definition_filter.pl -i \sf\tools\buildplatforms\build\data\S60_SystemBuild.xml %SYSTEM_CONFIGURATION_FILTER%
)

rem tools_cmaker
call cd \tools\cmaker && make

rem cmaker_S60_config
call cmd /c "cd \sf\os\deviceplatformrelease\sf_build\sf_prebuild && cmaker %CMAKER_BUILD% ACTION=export BUILD=%BUILD_PLATFORM%"


rem cmaker_s60_51_config
call cmd /c "cd \config\s60_52_config && cmaker s60_52_config ACTION=export BUILD=oem S60=52"


echo Remove possible scanlog because htmlscanlog.pl do not overwrite it 
if exist %LOGS_PATH%scanlog_S60Build_xml.html (
call del /q %LOGS_PATH%scanlog_S60Build_xml.html
)

echo Generate bldmelast.xml for %BUILD_PLATFORM%
call perl \epoc32\tools\build\genxml.pl -x \epoc32\tools\s60tools\S60_SystemBuild.xml -x \epoc32\tools\s60tools\S60_SystemModel.xml -x \epoc32\tools\s60tools\custom_SystemDefinition.xml -n %BUILD_PLATFORM%_bldmelast -s \ -o \epoc32\tools\s60tools\bldmelast.xml -l %LOGS_PATH%bldmelast_xml.log
set CONFIGURATION_LOG_FILES=%CONFIGURATION_LOG_FILES% -l %LOGS_PATH%bldmelast_xml.log

echo Generate S60Build.xml for %S60_BUILD_CONFIGURATION% build
call perl \epoc32\tools\build\genxml.pl -x \epoc32\tools\s60tools\S60_SystemBuild.xml -x \epoc32\tools\s60tools\S60_SystemModel.xml -x \epoc32\tools\s60tools\custom_SystemDefinition.xml -n %S60_BUILD_CONFIGURATION% -s \ -o \epoc32\tools\s60tools\S60Build.xml -l %LOGS_PATH%S60Build_xml.log
set CONFIGURATION_LOG_FILES=%CONFIGURATION_LOG_FILES% -l %LOGS_PATH%S60Build_xml.log


echo Generate summary scanlog from generated build xml files
call perl \epoc32\tools\htmlscanlog.pl %CONFIGURATION_LOG_FILES% -o %LOGS_PATH%scanlog_S60Build_xml.html -v


perl -le "$time=localtime; print '=== Stage=1 finished ', $time"
endlocal
