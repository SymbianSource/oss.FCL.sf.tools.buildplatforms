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
perl -le "$time=localtime; print '=== Stage=1 started ', $time"

if not "%1" == "" (
set BLDLAYER_CONFIGURATION=%1
) else (
set BLDLAYER_CONFIGURATION=build
)


if not defined LOGS_PATH (
	set LOGS_PATH=.\
)

if not exist %LOGS_PATH% (
echo create folder for logs
md %LOGS_PATH%
)

if not defined BUILD_XML_PATH (
	set BUILD_XML_PATH=.\
)

if not exist %BUILD_XML_PATH% (
echo create folder for build xml file
md %BUILD_XML_PATH%
)


echo Build logs will be written to %LOGS_PATH%

if exist %LOGS_PATH%scanlog_%BLDLAYER_CONFIGURATION%.html (
echo Remove old scanlog because htmlscanlog.pl do not overwrite it 
call del /q %LOGS_PATH%scanlog_%BLDLAYER_CONFIGURATION%.html
)


if exist .\systemDefinition.xml ( 
if exist .\systemDefinitionLayer.xml (
echo needed files exist to %BLDLAYER_CONFIGURATION% Ado
set SGML_SEARCH_PATH=\epoc32\tools\systemDefinition\
echo perl \epoc32\tools\build\genxml.pl -x .\systemDefinition.xml -n %BLDLAYER_CONFIGURATION% -s \ -o %BUILD_XML_PATH%%BLDLAYER_CONFIGURATION%.xml -l %LOGS_PATH%%BLDLAYER_CONFIGURATION%_xml.log
call perl \epoc32\tools\build\genxml.pl -x .\systemDefinition.xml -n %BLDLAYER_CONFIGURATION% -s \ -o %BUILD_XML_PATH%%BLDLAYER_CONFIGURATION%.xml -l %LOGS_PATH%%BLDLAYER_CONFIGURATION%_xml.log
) else (
echo systemDefinitionLayer.xml not found, %BLDLAYER_CONFIGURATION% Ido
set SGML_SEARCH_PATH=\epoc32\tools\systemDefinition\
echo perl \epoc32\tools\build\genxml.pl -x .\systemDefinition.xml -n %BLDLAYER_CONFIGURATION% -s \ -o %BUILD_XML_PATH%%BLDLAYER_CONFIGURATION%.xml -l %LOGS_PATH%%BLDLAYER_CONFIGURATION%_xml.log
call perl \epoc32\tools\build\genxml.pl -x .\systemDefinition.xml -n %BLDLAYER_CONFIGURATION% -s \ -o %BUILD_XML_PATH%%BLDLAYER_CONFIGURATION%.xml -l %LOGS_PATH%%BLDLAYER_CONFIGURATION%_xml.log
)
) else (
echo systemDefinition.xml not found
goto :end
)

echo Building ...
call \epoc32\tools\s60tools\build_tbs.cmd %BLDLAYER_CONFIGURATION% %BUILD_XML_PATH%

:end
perl -le "$time=localtime; print '=== Stage=1 finished ', $time"
endlocal

