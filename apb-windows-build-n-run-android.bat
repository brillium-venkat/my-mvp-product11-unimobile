:: =======================================================================================================================
:: AppBrahma Android Unimobile App building and running
:: Author :Venkateswar Reddy Melachervu
:: History:
::	16-12-2021 - Creation
::  17-12-2021 - Added gracious error handling and recovery mechansim for already added android platform
::  26-12-2021 - Added error handling and android sdk path check
::  20-01-2022 - Created script for linux
::  29-01-2022 - Updated
::  27-02-2022 - Updated for streamlining exit error codes and re-organizing build code into a function for handling 
::               dependency version incompatibilities
::	07-03-2022 - Updated for function exit codes, format and app display prefix
::	08-03-2022 - Updated for pre-req version validations
::	12-03-2022 - Updated for installation checks and de-cluttering the console output by capturing the output into env variable
::	23-03-2022 - HTTPS self signed cert deployment and api level support
::  24-03-2022 - Merging both batch files for http and https
:: =======================================================================================================================

@echo off
Setlocal EnableDelayedExpansion
set "MOBILE_GENERATOR_NAME=UniBrahma"
set "CERT_DEPLOYER=Unimobile Cert Deployer"
title %MOBILE_GENERATOR_NAME%
set "TERM_TITLE=%MOBILE_GENERATOR_NAME%"
set "MOBILE_GENERATOR_LINE_PREFIX=[%MOBILE_GENERATOR_NAME%]"
set "CERT_DEPLOYER_LINE_PREFIX=[%CERT_DEPLOYER%]"
set "NODE_MAJOR_VERSION=16"
set "NPM_MAJOR_VERSION=6"
set "IONIC_CLI_MAJOR_VERSION=6"
set "IONIC_CLI_MINOR_VERSION=16"
set "JAVA_MIN_VERSION=11"
set "JAVA_MIN_MAJOR_VERSION=11"
set "JAVA_MIN_MINOR_VERSION=0"

:: cert deployment related
set "EXIT_CERT_DEPLOYER_EXIT_CODE_BASE=150"
set "EXIT_ADB_EMULATOR_PATHS_ERROR=151"
set "EXIT_COMMAND_ERROR_CODE=152"
set "EXIT_ANDROID_HOME_PATH_COMMAND_ERROR_CODE=153"
set "EXIT_ADB_DEV_LIST_COMMAND_ERROR_CODE=154"
set "EXIT_EMULATOR_HELP_COMMAND_ERROR_CODE=155"
set "EXIT_ADB_HELP_COMMAND_ERROR_CODE=156"
set "EXIT_EMULATOR_LIST_AVDS_HELP_COMMAND_ERROR_CODE=157"
set "EXIT_ADB_LIST_DEVICES_HELP_COMMAND_ERROR_CODE=158"
set "EXIT_NO_DEVICE_CONNECTED_ERROR_CODE=159"
set "EXIT_OPENSSL_NOT_IN_PATH_ERROR_CODE=160"
set "EXIT_CERT_HASH_GEN_COMMAND_ERROR_CODE=161"
set "EXIT_RUN_EMULATOR_COMMAND_ERROR_CODE=162"
set "EXIT_RESTART_ADB_AS_ROOT_COMMAND_ERROR_CODE=163"
set "EXIT_DISABLE_SECURE_ROOT_COMMAND_ERROR_CODE=164"
set "EXIT_ADB_REBOOT_COMMAND_ERROR_CODE=165"
set "EXIT_REMOUNT_PARTITIONS_COMMAND_ERROR_CODE=166"
set "EXIT_PUSH_SIGNED_CERT_COMMAND_ERROR_CODE=167"
set "EXIT_SET_CERT_PERMS_COMMAND_ERROR_CODE=168"

:: build and run related
set "EXIT_ERROR_CODE=200"
set "EXIT_WINDOWS_VERSION_CHECK_COMMAND_ERROR_CODE=201"
set "EXIT_NODE_VERSION_CHECK_COMMAND_ERROR_CODE=202"
set "EXIT_NPM_VERSION_CHECK_COMMAND_ERROR_CODE=203"
set "EXIT_IONIC_CLI_VERSION_CHECK_COMMAND_ERROR_CODE=204"
set "EXIT_JAVA_VERSION_CHECK_COMMAND_ERROR_CODE=205"
set "EXIT_JDK_VERSION_CHECK_COMMAND_ERROR_CODE=206"
set "EXIT_EMULATOR_HELP_COMMAND_ERROR_CODE=207"
set "EXIT_NPM_INSTALL_COMMAND_ERROR_CODE=208"
set "EXIT_IONIC_BUILD_COMMAND_ERROR_CODE=209"
set "EXIT_IONIC_CAP_ADD_PLATFORM_COMMAND_ERROR_CODE=210"
set "EXIT_UNIMO_INSTALL_BUILD_ERROR_CODE=211"
set "EXIT_IONIC_RE_RUN_INSTALL_AND_BUILD=212"
set "EXIT_CORDOVA_RES_COMMAND_INSTALL_ERROR_CODE=213"
set "EXIT_CORDOVA_RES_COMMAND_ERROR_CODE=214"
set "EXIT_ADB_VERSION_COMMAND_ERROR_CODE=215"
set "EXIT_IONIC_CAP_RUN_COMMAND_ERROR_CODE=216"
set "EXIT_GET_SDK_API_LEVEL_ERROR_CODE=217"
set "EXIT_ADB_REVERSE_COMMAND_ERROR_CODE=218"
set "EXIT_WRONG_PARAMS_ERROR_CODE=219"
set "EXIT_EMULATOR_LIST_AVDS_COMMAND_ERROR_CODE=220"
set "EXIT_PROJ_REBUILD_ERROR_CODE=221"
set "EXIT_PRE_REQ_CHECK_FAILURE_CODE=222"
set "EXIT_CERT_DEPLOYMENT_PRE_REQ_CHECK_FAILURE_CODE=223"
set "EXIT_CERT_DEPLOYMENT_FAILURE_CODE=224"
set "EXIT_ANDROID_HOME_NOT_SET_CODE=225"
set "EXIT_EMULATOR_EXE_PATH_NOT_PROPERLY_SET_CODE=226"
set "EXIT_ANDROID_PLATFORM_TOOLS_NOT_IN_PATH_CODE=227"
set "EXIT_ANDROID_SDK_TOOLS_NOT_SET_IN_PATH_CODE=228"
set "EXIT_ANDROID_SDK_PATH_NOT_SET_IN_PATH_CODE=229"

set "output_tmp_file=.unibrahma-build-n-run.tmp"
set "child1_output_tmp_file=.unibrahma-build-n-run-child-1.tmp"
set "emu_menu_opts=.unibrahma-build-n-run-emu-menu-opts.tmp"
set "hash_named_cert="
set /A "APPBRAHMA_CERT_DEPLOYMENT=1"
set /A "THIRD_PARTY_CERT_DEPLOYED=2"
set /A "INVALID_CERT_ISSUER_SELECTION=3"
set /A cap_android_platform_reinstall=0
set "target="
:: arguments
:: usage <script_name> build/rebuild http/https
set "build_rebuild=%1"
set "server_rest_api_mode=%2"
set /A "arg_count=0"

:: args count
for %%g in (%*) do (
	set /A arg_count+=1
)
if !arg_count! LSS 2 ( 
	echo %MOBILE_GENERATOR_LINE_PREFIX% : Invalid arguments supplied to the script^^!	
	echo.
	echo Usage:			
	echo 	apb-windows-build-n-run-android.sh ^<build_task_type^> ^<server_protocol^>
	echo 	Example 1 : "apb-windows-build-n-run-android.sh build http"
	echo 	Example 2 : "apb-windows-build-n-run-android.sh build https"
	echo 	Example 3 : "apb-windows-build-n-run-android.sh rebuild http"
	echo 	Example 4 : "apb-windows-build-n-run-android.sh rebuild https"
	exit /b %EXIT_WRONG_PARAMS_ERROR_CODE%		
)

:: clear the screen for better visibility
cls
if exist !output_tmp_file! (
	for /F "tokens=*" %%G in ('del /F !output_tmp_file!' ) do (									
		set "del_result=%%G"
	)		
) 
if exist !child1_output_tmp_file! (
	for /F "tokens=*" %%G in ('del /F !child1_output_tmp_file!' ) do (									
		set "del_result=%%G"
	)		
) 
if exist !emu_menu_opts! (
	for /F "tokens=*" %%G in ('del /F !emu_menu_opts!' ) do (									
		set "del_result=%%G"
	)		
) 

echo ==========================================================================================================================================
echo 				Welcome to %MOBILE_GENERATOR_NAME% Unimobile app build and run script for development and testing - non-production
echo Sit back, relax, and sip a cup of coffee while the dependencies are downloaded, project is built, and run. 
echo Unless the execution of this script stops, do not be bothered nor worried about any warnings or errors displayed during the execution ;-^)
echo ==========================================================================================================================================
echo.

if "!build_rebuild!" == "rebuild" (
	echo %MOBILE_GENERATOR_LINE_PREFIX% : Rebuild is requested. Cleaning the project for the rebuild...
	if exist node_modules\ (
		call rmdir /S /Q "node_modules"  > "!output_tmp_file!" 2>&1			
		if !ERRORLEVEL! NEQ 0  (
			echo %MOBILE_GENERATOR_LINE_PREFIX% : Error removing node_modules directory for rebuilding^^!	
			echo %MOBILE_GENERATOR_LINE_PREFIX% : Error details are displayed below. Aborting the execution.
			echo %MOBILE_GENERATOR_LINE_PREFIX% : Please retry running the script after fixing these reported errors.			
			for /F "usebackq delims=" %%I in ("!output_tmp_file!") do echo %%I 								
			exit /b %EXIT_PROJ_REBUILD_ERROR_CODE%
		)
	)
	if exist android\ (
		call rmdir /S /Q "android"  > "!output_tmp_file!" 2>&1			
		if !ERRORLEVEL! NEQ 0  (
			echo %MOBILE_GENERATOR_LINE_PREFIX% : Error removing android platform for rebuilding^^!	
			echo %MOBILE_GENERATOR_LINE_PREFIX% : Error details are displayed below. Aborting the execution.
			echo %MOBILE_GENERATOR_LINE_PREFIX% : Please retry running the script after fixing these reported errors.			
			for /F "usebackq delims=" %%I in ("!output_tmp_file!") do echo %%I 								
			exit /b %EXIT_PROJ_REBUILD_ERROR_CODE%
		)
	)
	if exist www\ (
		call rmdir /S /Q "www"  > "!output_tmp_file!" 2>&1			
		if !ERRORLEVEL! NEQ 0  (
			echo %MOBILE_GENERATOR_LINE_PREFIX% : Error removing www platform for rebuilding^^!	
			echo %MOBILE_GENERATOR_LINE_PREFIX% : Error details are displayed below. Aborting the execution.
			echo %MOBILE_GENERATOR_LINE_PREFIX% : Please retry running the script after fixing these reported errors.			
			for /F "usebackq delims=" %%I in ("!output_tmp_file!") do echo %%I 								
			exit /b %EXIT_PROJ_REBUILD_ERROR_CODE%
		)
	)	
	echo %MOBILE_GENERATOR_LINE_PREFIX% : Project successfully cleaned.
)

echo %MOBILE_GENERATOR_LINE_PREFIX% : Validating pre-requisites... 
call :unimo_common_pre_reqs_validation
if !ERRORLEVEL! NEQ 0 (  	
	echo %MOBILE_GENERATOR_LINE_PREFIX% : Pre-requisites validation failed^^! 
	echo %MOBILE_GENERATOR_LINE_PREFIX% : Aborting the execution.
	echo %MOBILE_GENERATOR_LINE_PREFIX% : Please retry running this script after fixing the reported errors.
	exit /b %EXIT_PRE_REQ_CHECK_FAILURE_CODE%
)

:: https check for prep-up
if "!server_rest_api_mode!" == "https" (	
	echo %MOBILE_GENERATOR_LINE_PREFIX% : Unimobile app will be built and run for communicating with back-end server using HTTPS protocol.
	echo.
	echo %MOBILE_GENERATOR_LINE_PREFIX% : Please modify and ensure the web protocol in "apiUrl" key value to "https" in src/environments/environment.ts of 
	echo Unimobile sources project directory and save the file to proceed further.
	echo.
	echo	Example 1 - apiUrl: 'https://192.168.0.114:8091/api'
	echo	Example 2 - apiUrl: 'https://localhost:8091/api'
	echo.
	set /p asd="%MOBILE_GENERATOR_LINE_PREFIX% : Press any key to continue after modification and saving the file... "	
	echo.	
	call :cert_issuer_selection_prompt
	if !ERRORLEVEL! EQU !INVALID_CERT_ISSUER_SELECTION! ( 		
		set "exit_code=!ERRORLEVEL!"
		exit /b !exit_code!
	) else (
		if !ERRORLEVEL! EQU !APPBRAHMA_CERT_DEPLOYMENT! ( 		
			echo %MOBILE_GENERATOR_LINE_PREFIX% : Validating pre-requisites for HTTPS certificate deployment... 	
			call :unimo_cert_deployment_pre_reqs_validation
			if !ERRORLEVEL! NEQ 0 (  	
				echo %MOBILE_GENERATOR_LINE_PREFIX% : HTTPS certificate deployment pre-requisites validation failed^^! 
				echo %MOBILE_GENERATOR_LINE_PREFIX% : Aborting the execution.
				echo %MOBILE_GENERATOR_LINE_PREFIX% : Please retry running this script after fixing the reported errors.
				exit /b %EXIT_CERT_DEPLOYMENT_PRE_REQ_CHECK_FAILURE_CODE%
			)
			echo %MOBILE_GENERATOR_LINE_PREFIX% : Pre-requisites for server certificate deployment are fulfilled. Continuing ahead.
			:: emulator select menu
			if exist !emu_menu_opts! (
				for /F "tokens=*" %%G in ('del /F !emu_menu_opts!') do (									
					set "del_result=%%G"
				)		
			) 
			call emulator -list-avds > "!output_tmp_file!" 2>&1
			if !ERRORLEVEL! NEQ 0 (  	
				echo %MOBILE_GENERATOR_LINE_PREFIX% : Error getting the list of configured AVDs^^! 
				echo %MOBILE_GENERATOR_LINE_PREFIX% : Error details are:
				for /F "usebackq delims=" %%I in ("!output_tmp_file!") do echo %%I
				echo %MOBILE_GENERATOR_LINE_PREFIX% : Aborting the execution.
				echo %MOBILE_GENERATOR_LINE_PREFIX% : Please retry running this script after configuring at least one AVD.
				exit /b %EXIT_ADB_LIST_DEVICES_HELP_COMMAND_ERROR_CODE%
			)
			echo.
			echo %CERT_DEPLOYER_LINE_PREFIX% : Which device would you like to target?
			set /A menu_counter=0
			for /f "tokens=*" %%G in (!output_tmp_file!) do (
				set /A menu_counter+=1
				echo !menu_counter!^) %%G
				echo !menu_counter!^) %%G >> !emu_menu_opts!
			)
			set /p choice="%CERT_DEPLOYER_LINE_PREFIX% : Please type the AVD number shown above for the target selection: "
			set "target="
			set "menu_counter="
			for /f "tokens=1,2" %%G in (!emu_menu_opts!) do (	
				if %%G == !choice!^) (
					set target=%%H		
					set menu_counter=%%G
				)
			)
			:: remove tabs
			set target=!target:	=!
			:: remove spaces
			set target=!target: =!
			echo.
			echo %CERT_DEPLOYER_LINE_PREFIX% : You have chosen "!menu_counter! !target!" as the target.			
			echo %CERT_DEPLOYER_LINE_PREFIX% : If the emulator is already running this AVD, please close the running AVD and emulator. 			
			echo %CERT_DEPLOYER_LINE_PREFIX% : Additionally, if this AVD was created from the system image that is labelled or target as "Google Play" which runs a production build image, certificate cannot be deployed. 			
			echo %CERT_DEPLOYER_LINE_PREFIX% : If you try to run this script or deploy on the production build image, then this script would crash during the execution.
			set /p asd="%CERT_DEPLOYER_LINE_PREFIX% : Press any key to continue, when ready..."
			echo.			
			call :unimo_deploy_server_cert_to_device
			if !ERRORLEVEL! NEQ 0 (  	
				echo %MOBILE_GENERATOR_LINE_PREFIX% : HTTPS certificate deployment failed^^! 
				echo %MOBILE_GENERATOR_LINE_PREFIX% : Aborting the execution.
				echo %MOBILE_GENERATOR_LINE_PREFIX% : Please retry running this script after fixing the reported errors.
				exit /b %EXIT_CERT_DEPLOYMENT_FAILURE_CODE%
			)		
		)
	)
) else (
	if "!server_rest_api_mode!" == "http" (
		echo %MOBILE_GENERATOR_LINE_PREFIX% : Unimobile app will be built and run for communicating with back-end server using HTTP protocol.
		echo.
		echo %MOBILE_GENERATOR_LINE_PREFIX% : Please modify and ensure the web protocol in "apiUrl" key value to "http" in src/environments/environment.ts of 
		echo Unimobile sources project directory and save the file to proceed further.
		echo.
		echo	Example 1 - apiUrl: 'http://192.168.0.114:8091/api'
		echo	Example 2 - apiUrl: 'http://localhost:8091/api'
		echo.
		set /p asd="%MOBILE_GENERATOR_LINE_PREFIX% : Press any key to continue after modification and saving the file... "	
		echo.			
	) else (
		echo %MOBILE_GENERATOR_LINE_PREFIX% : Invalid argument value provided for server protocol. Aborting the execution.								
		exit /b %EXIT_WRONG_PARAMS_ERROR_CODE%	
	)
)

call :unimo_install_ionic_deps_build_and_platform
if !ERRORLEVEL! NEQ 0 (  	
	echo %MOBILE_GENERATOR_LINE_PREFIX% : Error in building the project and installing android platform^^! 
	echo %MOBILE_GENERATOR_LINE_PREFIX% : Error details are displayed above. Aborting the execution.
	echo %MOBILE_GENERATOR_LINE_PREFIX% : Please retry running this script after fixing the displayed errors.
	exit /b !ERRORLEVEL!
)

:: cordova-res install check - local
:: call npm list cordova-res > "!output_tmp_file!" 2>&1
:: if !ERRORLEVEL! NEQ 0 (  	
::	echo %MOBILE_GENERATOR_LINE_PREFIX% : "npm list cordova-res" command execution result is : !ERRORLEVEL!
::	echo %MOBILE_GENERATOR_LINE_PREFIX% : Error details are below:
::	for /F "usebackq delims=" %%I in ("!output_tmp_file!") do echo %%I
::) else (
::	echo %MOBILE_GENERATOR_LINE_PREFIX% : "npm list cordova-res" command execution result is : !ERRORLEVEL!
::	echo %MOBILE_GENERATOR_LINE_PREFIX% : out details are below:
::	for /F "usebackq delims=" %%I in ("!output_tmp_file!") do echo %%I
::)
:: cordova-res install check - global
call npm list -g cordova-res > "!output_tmp_file!" 2>&1
if !ERRORLEVEL! NEQ 0 (  	
	echo %MOBILE_GENERATOR_LINE_PREFIX% : cordova-res node module is not installed. This is needed for Unimobile app icon and splash customization.
	echo %MOBILE_GENERATOR_LINE_PREFIX% : Installing cordova-res...
	call npm install -g cordova-res > "!output_tmp_file!" 2>&1
	if !ERRORLEVEL! NEQ 0 (  	
		echo %MOBILE_GENERATOR_LINE_PREFIX% : Error installing cordova-res node module^^!
		echo %MOBILE_GENERATOR_LINE_PREFIX% : Error details are:
		for /F "usebackq delims=" %%I in ("!output_tmp_file!") do echo %%I
		echo %MOBILE_GENERATOR_LINE_PREFIX% : Aborting the execution. Please retry running this script after fixing the reported issues.
		exit /b %EXIT_CORDOVA_RES_COMMAND_INSTALL_ERROR_CODE%	
	)	
)
echo %MOBILE_GENERATOR_LINE_PREFIX% : Customizing Unimobile application icon and splash images...
call cordova-res android --skip-config --copy > "!output_tmp_file!" 2>&1
if !ERRORLEVEL! NEQ 0 (
    echo %MOBILE_GENERATOR_LINE_PREFIX% : Error customizing the application icon and splash images^^!
	echo %MOBILE_GENERATOR_LINE_PREFIX% : Error details are:
	for /F "usebackq delims=" %%I in ("!output_tmp_file!") do echo %%I
    echo %MOBILE_GENERATOR_LINE_PREFIX% : Aborting the execution. Please retry running this script after fixing the reported issues.    
    exit /b !ERRORLEVEL!
)
if "!server_rest_api_mode!" == "https" (
	echo %MOBILE_GENERATOR_LINE_PREFIX% : Deploying and running the Unimobile app on !target!...
) else (
	:: emulator select menu
	if exist !emu_menu_opts! del /F !emu_menu_opts!
	call emulator -list-avds > "!output_tmp_file!" 2>&1
	echo.
	echo %MOBILE_GENERATOR_LINE_PREFIX% : Which device would you like to target?
	set /A menu_counter=0
	for /f "tokens=*" %%G in (!output_tmp_file!) do (
		set /A menu_counter+=1
		echo !menu_counter!^) %%G
		:: to retrive target based on user typed selection number
		echo !menu_counter!^) %%G >> !emu_menu_opts!
	)
	set /p choice="%MOBILE_GENERATOR_LINE_PREFIX% : Please type the emulator number shown above for the target selection: "	
	set "menu_counter="
	for /f "tokens=1,2" %%G in (!emu_menu_opts!) do (	
		if %%G == !choice!^) (
			set target=%%H		
			set menu_counter=%%G
		)
	)
	:: remove tabs
	set target=!target:	=!
	:: remove spaces
	set target=!target: =!
	echo.
	echo %MOBILE_GENERATOR_LINE_PREFIX% : You have chosen !menu_counter! !target!
	echo.
	echo %MOBILE_GENERATOR_LINE_PREFIX% : Starting Android emulator for running the Unimobile app on !target!...
)
call ionic cap run android --target !target! > "!output_tmp_file!" 2>&1
if !ERRORLEVEL! NEQ 0 (
    echo %MOBILE_GENERATOR_LINE_PREFIX% : Error running Android emulator and running your Unimobile application^^!
	echo %MOBILE_GENERATOR_LINE_PREFIX% : Error details are:
	for /F "usebackq delims=" %%I in ("!output_tmp_file!") do echo %%I 
    echo %MOBILE_GENERATOR_LINE_PREFIX% : Please retry running this script after deleting the node_modules, android, and www directories in this project folder, if they exist.
    exit /b !ERRORLEVEL!
)

echo %MOBILE_GENERATOR_LINE_PREFIX% : Configuring Android emulator to access the Appbrahma server port on the network...
call adb reverse tcp:8091 tcp:8091 2>&1
if !ERRORLEVEL! NEQ 0 (
    echo %MOBILE_GENERATOR_LINE_PREFIX% : Error confuguring android emulator to access the server port on the network^^!    
	echo %MOBILE_GENERATOR_LINE_PREFIX% : Error details are:
	for /F "usebackq delims=" %%I in ("!output_tmp_file!") do echo %%I 
    echo %MOBILE_GENERATOR_LINE_PREFIX% : Please try executing the command - adb reverse tcp:8091 tcp:8091 - for establishing seamless connection between server and this app for REST calls.    
    exit /b !ERRORLEVEL!
)
:: Display credentials for log in - for server integrated template
echo %MOBILE_GENERATOR_LINE_PREFIX% : Please use the below login credentials to login to the appbrahma generated server from the Unimobile app after running the backend server in a seperate console window
echo 	Username: brahma
echo 	Password: brahma@appbrahma

if exist !output_tmp_file! (
	for /F "tokens=*" %%G in ('del /F !output_tmp_file!') do (									
		set "del_result=%%G"
	)		
) 
if exist !child1_output_tmp_file! (
	for /F "tokens=*" %%G in ('del /F !child1_output_tmp_file!') do (									
		set "del_result=%%G"
	)		
) 
if exist !emu_menu_opts! (
	for /F "tokens=*" %%G in ('del /F !emu_menu_opts!') do (									
		set "del_result=%%G"
	)		
) 
endlocal
exit /b 0
:: end of main script

:: https initial prompt - AppBrahma root CA signed server cert or 3rd party signed server cert?
:cert_issuer_selection_prompt	
	echo %MOBILE_GENERATOR_LINE_PREFIX% : For https support by Android App, a signed server certificate needs to be deployed onto the Android emulator/device 
	echo system store. Appbrahma MVP generator has already created AppBrahma root CA signed server certificate which will deployed now onto 
	echo Android emulator/device system store. This deployment step is needed to enable Unimobile app communicate with the back-end server using HTTPS for 
	echo testing the app.
	echo.
	echo %MOBILE_GENERATOR_LINE_PREFIX% : For this or any third party root CA signed server certificate deployment where the root CA certificate is not 
	echo deployed in the Android system store by default, AVD must not run a production build to enable so-signed root CA certificate deployment to the 
	echo emulator device.
	echo.
	echo %MOBILE_GENERATOR_LINE_PREFIX% : This certificate deployment step is NOT needed if you use server signed certificate issued by a root CA
	echo whose root certificate is already deployed onto the Android system store you are targeting to test or if you are using  HTTP protocol.
	echo.

	:: AppBrahma cert or third part cert?
	echo %MOBILE_GENERATOR_LINE_PREFIX% : Would you like to :
	echo 	1^) Continue with AppBrahma root CA signed server certificate deployment to emulator/device or
	echo 	2^) Continue with a third party signed server certificate which is already deployed to device/emulator system store
	echo.
	set /p selection="Please type the number of the option displayed above for your selection and hit enter: "	
	echo.
	echo %MOBILE_GENERATOR_LINE_PREFIX% : You have selected option !selection!
	echo.
	if !selection! EQU 2 (
		echo %MOBILE_GENERATOR_LINE_PREFIX% : Skipping the AppBrahma root CA server certificate deployment process...
		exit /b !THIRD_PARTY_CERT_DEPLOYED!
	) else (
		if !selection! NEQ 1 (
			echo %MOBILE_GENERATOR_LINE_PREFIX% : You have typed an invalid value !selection! for the selection^^! 
			echo %MOBILE_GENERATOR_LINE_PREFIX% : Valid values are 1 or 2. Aborting the execution. 
			echo %MOBILE_GENERATOR_LINE_PREFIX% : Please retry with valid values for the selection.
			exit /b %INVALID_CERT_ISSUER_SELECTION%
		)
	)
	exit /b !APPBRAHMA_CERT_DEPLOYMENT!

:: common pre-req checks
:unimo_common_pre_reqs_validation
	:: windows os name and version
	set "for_exec_result="
	echo %MOBILE_GENERATOR_LINE_PREFIX% : Your Windows version details are :
	for /F "tokens=*" %%G in ('systeminfo ^| findstr /B /C:"OS Name" /C:"OS Version"') do (			
		set ver_token=%%G
		set ver_token=!ver_token: =!
		for /F "tokens=1,2 delims=:" %%J in ("!ver_token!") do (
			echo 	%%J : %%K
		)				
	)
	:: nodejs install check
	call node --version 2>nul 1> nul
	if !ERRORLEVEL! NEQ 0 ( 
		set "exit_code=!ERRORLEVEL!"
		echo %MOBILE_GENERATOR_LINE_PREFIX% : Nodejs is NOT installed^^!
		echo %MOBILE_GENERATOR_LINE_PREFIX% : Please install a stable and LTS version of nodejs major release %NODE_MAJOR_VERSION% and retry running this script.
		exit /b !exit_code! 
	)
	:: nodejs version check
	for /F "tokens=*" %%G in ('node --version') do (									
		set "for_exec_result=%%G"
	)	
	for /f "tokens=1,2,3 delims=." %%G in ("!for_exec_result!") do (	
		set "raw_major_ver=%%G"	
		for /f "tokens=1 delims=v" %%J in ("!raw_major_ver!") do (
			set "major_verion=%%J"
		)			
		if !major_verion! LSS %NODE_MAJOR_VERSION% (
			echo %MOBILE_GENERATOR_LINE_PREFIX% : You are running non-supported nodejs version "%%G.%%H.%%I"^^!
			echo %MOBILE_GENERATOR_LINE_PREFIX% : Minimum required version is %NODE_MAJOR_VERSION%+. Please upgrade nodejs and retry this script.
			echo %MOBILE_GENERATOR_LINE_PREFIX% : Aborting the build process^^!		
			exit /b %EXIT_NODE_VERSION_CHECK_COMMAND_ERROR_CODE%
		)
	)
	echo %MOBILE_GENERATOR_LINE_PREFIX% : Nodejs version requirement - !for_exec_result! - met. Continuing ahead...

	:: npm install check
	call npm --version 2>nul 1> nul
	if !ERRORLEVEL! NEQ 0 ( 
		set "exit_code=!ERRORLEVEL!"
		echo %MOBILE_GENERATOR_LINE_PREFIX% : npm is NOT installed^^!
		echo %MOBILE_GENERATOR_LINE_PREFIX% : Please install a stable and LTS version of npm major release %NPM_MAJOR_VERSION% and retry running this script.
		exit /b !exit_code! 
	)
	:: npm version check
	for /F "tokens=*" %%G in ('npm --version') do (									
		set "for_exec_result=%%G"
	)	
	for /f "tokens=1,2,3 delims=." %%G in ("!for_exec_result!") do (		
		if %%G LSS %NPM_MAJOR_VERSION% (
			echo %MOBILE_GENERATOR_LINE_PREFIX% : You are running non-supported "npm version %%G.%%H.%%I" for building and running AppBrahma generated Unimobile application project sources^^!
			echo %MOBILE_GENERATOR_LINE_PREFIX% : Minimum required version is %NPM_MAJOR_VERSION%+. Please upgrade npm and retry this script.
			echo %MOBILE_GENERATOR_LINE_PREFIX% : Aborting the build process^^!
			exit /b %EXIT_NPM_VERSION_CHECK_COMMAND_ERROR_CODE%
		)
	)
	echo %MOBILE_GENERATOR_LINE_PREFIX% : NPM version requirement - !for_exec_result! - met. Continuing ahead...

	:: ionic cli install check
	call ionic --version 2>nul 1> nul
	if !ERRORLEVEL! NEQ 0 ( 
		set "exit_code=!ERRORLEVEL!"
		echo %MOBILE_GENERATOR_LINE_PREFIX% : Ionic CLI is NOT installed^^!
		echo %MOBILE_GENERATOR_LINE_PREFIX% : Please install a stable and LTS version of Ionic CLI major release %IONIC_CLI_MAJOR_VERSION% and retry running this script.
		exit /b !exit_code! 
	)
	:: ionic cli version check
	for /F "tokens=*" %%G in ('ionic --version') do (									
		set "for_exec_result=%%G"
	)	
	for /f "tokens=1,2,3 delims=." %%G in ("!for_exec_result!") do (		
		if %%G LSS %IONIC_CLI_MAJOR_VERSION% (
			echo %MOBILE_GENERATOR_LINE_PREFIX% : You are running non-supported "ionic version %%G.%%H.%%I" for building and running AppBrahma generated Unimobile application project sources^^!
			echo %MOBILE_GENERATOR_LINE_PREFIX% : Minimum required version is %IONIC_CLI_MAJOR_VERSION%+. Please upgrade npm and retry this script.
			echo %MOBILE_GENERATOR_LINE_PREFIX% : Aborting the build process^^!
			exit /b %EXIT_NPM_VERSION_CHECK_COMMAND_ERROR_CODE%
		) 
	)
	echo %MOBILE_GENERATOR_LINE_PREFIX% : Ionic CLI version requirement - !for_exec_result! - met. Continuing ahead...

	:: Java install check
	call java -version 2>nul 1> nul
	if !ERRORLEVEL! NEQ 0 ( 
		set "exit_code=!ERRORLEVEL!"
		echo %MOBILE_GENERATOR_LINE_PREFIX% : Java runtime is NOT installed^^!
		echo %MOBILE_GENERATOR_LINE_PREFIX% : Please install a stable and LTS version of Java/JDK major release %JAVA_MIN_MAJOR_VERSION% and retry running this script.
		exit /b !exit_code! 
	)
	:: java runtime version check
	set "first_line_string="
	set "first_line=1"
	for /F "tokens=*" %%G in ('java -version  2^>^&1 1^> nul') do (	
		if !first_line! EQU 1 (
			set "first_line_string=%%G"
			set /a first_line=!first_line!+1
		)	
	)	
	set "third_token="
	::  percent~I on commandline or percent percent~I in batch file expands percent I removing any surrounding quotes	
	for /F "tokens=1,2,3,4,5 delims= " %%G in ("!first_line_string!") do (			
		set "third_token=%%~I"		
	)
	set "java_major_version="
	set "java_minor_version="
	set "java_patch_version="
	for /F "tokens=1,2,3 delims=." %%G in ("!third_token!") do (
		set java_major_version=%%G
		set java_minor_version=%%H
		set java_patch_version=%%I
	)
	set first_part_mis_match=0
	set second_part_mis_match=0
	if !java_major_version! LSS %JAVA_MIN_MAJOR_VERSION% (
		set first_part_mis_match=1
	)
	if !java_minor_version! LSS %JAVA_MIN_MAJOR_VERSION% (
		set second_part_mis_match=1
	)

	if first_part_mis_match EQU second_part_mis_match (
		echo %MOBILE_GENERATOR_LINE_PREFIX% : You are running non-supported Java version !third_token! 
		echo %MOBILE_GENERATOR_LINE_PREFIX% : Minimum required major version is %JAVA_MIN_MAJOR_VERSION+%
		echo %MOBILE_GENERATOR_LINE_PREFIX% : Aborting the build process. Please install a stable and LTS java release of major version %JAVA_MIN_MAJOR_VERSION%+ and retry running this script.    
		exit /b %EXIT_JAVA_VERSION_CHECK_COMMAND_ERROR_CODE%
	)			
	echo %MOBILE_GENERATOR_LINE_PREFIX% : Java runtime version requirement - !third_token! - met. Continuing ahead...

	:: jdk check
	call javac --version  2>nul 1>nul
	if !ERRORLEVEL! NEQ 0 (
		echo %MOBILE_GENERATOR_LINE_PREFIX% : Java SDK appears to be not installed or NOT in PATH!    
		echo %MOBILE_GENERATOR_LINE_PREFIX% : Please install or update PATH for Java JDK and retry running this script^^!
		exit /b %EXIT_JDK_VERSION_CHECK_COMMAND_ERROR_CODE%
	)
	echo %MOBILE_GENERATOR_LINE_PREFIX% : Java JDK found in the path for building app and running emulator. Continuing ahead...

	:: android environment variables check - android_home, platform-tools, emulator, tools\bin	
	if exist !output_tmp_file! del /F !output_tmp_file!
	call echo %ANDROID_HOME% 2>&1 | find /i "android\sdk" > !output_tmp_file! 2>&1
	:: if the find result is empty writing to file results in error raising errorlevel to non-zero
	if !ERRORLEVEL! NEQ 0 ( 				
		echo %MOBILE_GENERATOR_LINE_PREFIX% : ANDROID_HOME environment varible is not set^^!
		echo %MOBILE_GENERATOR_LINE_PREFIX% : Please set this variable value - usually !USERPROFILE!\AppData\Local\Android\Sdk - and retry running this script.
		exit /b %EXIT_ANDROID_HOME_NOT_SET_CODE%
	)
	
	call echo %PATH% 2>&1 | find /i "android\sdk" > !output_tmp_file! 2>&1	
	if !ERRORLEVEL! NEQ 0 ( 				
		echo %MOBILE_GENERATOR_LINE_PREFIX% : Android SDK path is NOT set in PATH environment variable^^!
		echo %MOBILE_GENERATOR_LINE_PREFIX% : Please set this path value - usually !USERPROFILE!\AppData\Local\Android\Sdk - and retry running this script.
		exit /b %EXIT_ANDROID_SDK_PATH_NOT_SET_IN_PATH_CODE%
	)

	call echo %PATH% 2>&1 | find /i "android\sdk\platform-tools" > !output_tmp_file! 2>&1	
	if !ERRORLEVEL! NEQ 0 ( 				
		echo %MOBILE_GENERATOR_LINE_PREFIX% : Android SDK Platform tools path is NOT set in PATH environment variable^^!
		echo %MOBILE_GENERATOR_LINE_PREFIX% : Please set this path value - usually !USERPROFILE!\AppData\Local\Android\Sdk\platform-tools - and retry running this script.
		exit /b %EXIT_ANDROID_PLATFORM_TOOLS_NOT_IN_PATH_CODE%
	)

	call echo %PATH% 2>&1 | find /i "android\sdk\emulator" > !output_tmp_file! 2>&1	
	if !ERRORLEVEL! NEQ 0 ( 				
		echo %MOBILE_GENERATOR_LINE_PREFIX% : Android emulator path - correct value - is NOT set in PATH environment variable^^!
		echo %MOBILE_GENERATOR_LINE_PREFIX% : Please set this path value - usually !USERPROFILE!\AppData\Local\Android\Sdk\emulator - and retry running this script.
		exit /b %EXIT_EMULATOR_EXE_PATH_NOT_PROPERLY_SET_CODE%
	)

	call echo %PATH% 2>&1 | find /i "android\sdk\tools\bin" > !output_tmp_file! 2>&1	
	if !ERRORLEVEL! NEQ 0 ( 				
		echo %MOBILE_GENERATOR_LINE_PREFIX% : Android SDK tools path is NOT set in PATH environment variable^^!
		echo %MOBILE_GENERATOR_LINE_PREFIX% : Please set this path value - usually !USERPROFILE!\AppData\Local\Android\Sdk\tools\bin - and retry running this script.
		exit /b %EXIT_ANDROID_SDK_TOOLS_NOT_SET_IN_PATH_CODE%
	)

	call where emulator 2>&1 | find /i "android\sdk\emulator\emulator.exe" > !output_tmp_file! 2>&1	
	if !ERRORLEVEL! NEQ 0 ( 				
		echo %MOBILE_GENERATOR_LINE_PREFIX% : Android emulator path is NOT set at all or not set properly in PATH environment variable^^!
		call where emulator > !output_tmp_file! 2>&1	
		for /F "tokens=* usebackq delims=" %%I in (!output_tmp_file!) do (
			echo %MOBILE_GENERATOR_LINE_PREFIX% : The error is :
			echo %%I 
		)				
		echo %MOBILE_GENERATOR_LINE_PREFIX% : Please set proper emulator executable path value - usually !USERPROFILE!\AppData\Local\Android\Sdk\emulator\emulator.exe - and retry running this script.
		exit /b %EXIT_EMULATOR_EXE_PATH_NOT_PROPERLY_SET_CODE%
	)
	if exist !output_tmp_file! del /F !output_tmp_file!

	:: adb command check
	call adb --version 2>&1 > "!output_tmp_file!" 2>&1
	if !ERRORLEVEL! NEQ 0 ( 				
		echo %MOBILE_GENERATOR_LINE_PREFIX% : adb command executable path is not found. Either Android SDK tools not installed or adb executable path is NOT set in PATH^^!
		echo %MOBILE_GENERATOR_LINE_PREFIX% : Please install the same and/or set the PATH variable and retry running this script.
		exit /b %EXIT_ADB_VERSION_COMMAND_ERROR_CODE%
	)
	echo %MOBILE_GENERATOR_LINE_PREFIX% : adb executable is found to be in the PATH. Continuing ahead...	

	:: emulator command check
	call emulator -help 2>&1 > "!output_tmp_file!" 2>&1
	if !ERRORLEVEL! NEQ 0 ( 		
		echo %MOBILE_GENERATOR_LINE_PREFIX% : Emulator command executable path is not found. Either Android SDK tools not installed or emulator executable path is NOT set in PATH^^!
		echo %MOBILE_GENERATOR_LINE_PREFIX% : Please install the same and^/or set the PATH variable and retry running this script.
		exit /b %EXIT_EMULATOR_HELP_COMMAND_ERROR_CODE%
	)
	::for /F "usebackq delims=" %%I in ("!output_tmp_file!") do echo %%I 
	echo %MOBILE_GENERATOR_LINE_PREFIX% : Emulator executable is found to be in the PATH. Continuing ahead...

	:: at least one AVD should be configured
	call emulator -list-avds 2>&1 > "!output_tmp_file!" 2>&1
	if !ERRORLEVEL! NEQ 0 ( 		
		echo %MOBILE_GENERATOR_LINE_PREFIX% : Error getting the configured AVDs^^!
		echo %MOBILE_GENERATOR_LINE_PREFIX% : The error details are:
		for /F "usebackq delims=" %%I in ("!output_tmp_file!") do echo %%I 
		echo %MOBILE_GENERATOR_LINE_PREFIX% : Please fix emulator command execution errors displayed above and retry running this script.
		exit /b %EXIT_EMULATOR_LIST_AVDS_COMMAND_ERROR_CODE%
	)
	:: get configured AVDs count
	set /A avds=0
	for /F %%a in ('findstr /R . "!output_tmp_file!"') do (set /A avds=!avds!+1)
	if !avds! LSS 1 ( 		
		echo %MOBILE_GENERATOR_LINE_PREFIX% : Not a single Android Virtual Device - AVD - or Emulator image is set up^^!
		echo %MOBILE_GENERATOR_LINE_PREFIX% : Please set up at least one AVD and retry running this script.
		exit /b %EXIT_EMULATOR_HELP_COMMAND_ERROR_CODE%
	)	
	echo %MOBILE_GENERATOR_LINE_PREFIX% : Found "!avds!" AVDs configured for the emulator

	echo %MOBILE_GENERATOR_LINE_PREFIX% : Pre-requisites validation completed successfully.
	exit /b 0

:: cert deployment pre-req check
:unimo_cert_deployment_pre_reqs_validation
	echo %MOBILE_GENERATOR_LINE_PREFIX% : Validating pre-requisites for back-end server certificate deployment to the device...
	:: openSSL command check
	echo %MOBILE_GENERATOR_LINE_PREFIX% : Checking for openSSL...
	call openssl version > "!output_tmp_file!" 2>&1
	if !ERRORLEVEL! NEQ 0 ( 				
		echo %MOBILE_GENERATOR_LINE_PREFIX% : OpenSSL application is needed to deploy the certificate but the executable is not found in the PATH^^! 
		echo %MOBILE_GENERATOR_LINE_PREFIX% : Please install/fix the PATH for openSSL and retry running this script.	
		echo %MOBILE_GENERATOR_LINE_PREFIX% : FYI - OpenSSL binaries for windows can be downloaded from https://wiki.openssl.org/index.php/Binaries	
		exit /b %EXIT_OPENSSL_NOT_IN_PATH_ERROR_CODE%
	)
	echo %MOBILE_GENERATOR_LINE_PREFIX% : openSSL needed for certificate deployment onto emulator is found in the PATH. Continuing ahead...
	exit /b 0

:: server cert deployment to device
:unimo_deploy_server_cert_to_device
	setlocal EnableDelayedExpansion
	:: cert file check	
	set "signed_cert_name=appbrahma-root-ca-signed-server.crt"
	if NOT EXIST !signed_cert_name! (			
		echo %CERT_DEPLOYER_LINE_PREFIX% : AppBrahma root CA signed server certificate is not found in the Unimobile source code project directory^^!
		echo %CERT_DEPLOYER_LINE_PREFIX% : Aborting the execution.
		echo %CERT_DEPLOYER_LINE_PREFIX% : Please regenerate the application sources using AppBrahma platform and run this script from the newly generated Unimobile app project directory.
		exit /b %EXIT_CERT_HASH_GEN_COMMAND_ERROR_CODE%		
	)	
	:: Run selected emulator	
	echo %CERT_DEPLOYER_LINE_PREFIX% : Starting !target! to for the deployment preparation...
	start emulator -avd !target! -writable-system > "!child1_output_tmp_file!" 2>nul 1>nul
	if !ERRORLEVEL! NEQ 0 ( 				
		echo %CERT_DEPLOYER_LINE_PREFIX% : Error running !target!^^! 
		echo %CERT_DEPLOYER_LINE_PREFIX% : The error details are:
		for /F "usebackq delims=" %%I in ("!child1_output_tmp_file!") do echo %%I 
		echo %CERT_DEPLOYER_LINE_PREFIX% : Please fix above errors and retry running this script.
		exit /b %EXIT_RUN_EMULATOR_COMMAND_ERROR_CODE%
	)	
	echo.
	echo %CERT_DEPLOYER_LINE_PREFIX% : The selected emulator is spawned as an independent process. If you do not see emulator starting up or see errors, re-run 
	echo this script and select another emulator.
	echo.
	echo %CERT_DEPLOYER_LINE_PREFIX% : Wait for the emulator to boot up completely - until you see device home screen and then press any key to continue...
	echo.
	set /p asd="%CERT_DEPLOYER_LINE_PREFIX% : Press any key to continue, when ready... "	
	echo.

	:: check for avd image and connection to it
	call adb root > "!output_tmp_file!" 2>&1
	if !ERRORLEVEL! NEQ 0 ( 
		echo !CERT_DEPLOYER_LINE_PREFIX! : Unable to connect to !target! ^^!
		echo !CERT_DEPLOYER_LINE_PREFIX! : The error is:
		for /F "usebackq delims=" %%I in ("!output_tmp_file!") do echo %%I 
		echo %CERT_DEPLOYER_LINE_PREFIX% : Please ensure that you have waited until the emulator home screen was displayed and that the emulator was running in your retry.
		exit %EXIT_RESTART_ADB_AS_ROOT_COMMAND_ERROR_CODE%
	) else (
		:: if the image is production image, errorlevel still be 0 but displays a single line message - adbd cannot run as root in production builds
		for /f "tokens=*" %%I in ('adb root ^| find /i "cannot run as root in production builds"') do (
			echo %CERT_DEPLOYER_LINE_PREFIX% : The AVD you are running is a production image^^!
			echo %CERT_DEPLOYER_LINE_PREFIX% : Certificate cannot be deployed.
			echo %CERT_DEPLOYER_LINE_PREFIX% : Please retry with an AVD which is NOT a production image - that does not have Google Play as Target while creating it. 
			exit /b %EXIT_RESTART_ADB_AS_ROOT_COMMAND_ERROR_CODE%
		)
	)
	
	:: android sdk api level
	echo %CERT_DEPLOYER_LINE_PREFIX% : Finding device android sdk API level...
	call adb shell getprop ro.build.version.sdk > "!output_tmp_file!" 2>&1
	if !ERRORLEVEL! NEQ 0 ( 				
		echo %CERT_DEPLOYER_LINE_PREFIX% : Unable to get the connected device SDK API level. This is crucial for certificate deployment^^! 
		echo %CERT_DEPLOYER_LINE_PREFIX% : Please ensure the device/emulator is connected and developer settings are enabled as per the android version and retry running this script.
		echo %CERT_DEPLOYER_LINE_PREFIX% : The error details are:
		for /F "usebackq delims=" %%I in ("!output_tmp_file!") do echo %%I 
		echo %CERT_DEPLOYER_LINE_PREFIX% : Please fix above errors and retry running this script.
		exit /b %EXIT_GET_SDK_API_LEVEL_ERROR_CODE%
	)	
	for /F "usebackq delims=" %%I in ("!output_tmp_file!") do set "sdk_api_level=%%I"
	echo %CERT_DEPLOYER_LINE_PREFIX% : Found device android SDK API level - !sdk_api_level!
	if !sdk_api_level! GTR 28 (
		call :cert_deployment_to_devices_gt_sdk_api_level_28
		if !ERRORLEVEL! NEQ 0 ( 
			set "exit_code=!ERRORLEVEL!"
			exit /b !exit_code!
		)
	) else (
		call :cert_deployment_to_devices_leq_sdk_api_level_28
		if !ERRORLEVEL! NEQ 0 ( 
			set "exit_code=!ERRORLEVEL!"
			exit /b !exit_code!
		)
	)
	exit /b 0

:: cert deployment for sdk api level above 28
:cert_deployment_to_devices_gt_sdk_api_level_28
	call :signed_ca_cert_rename_for_android
	if !ERRORLEVEL! NEQ 0 ( 
		set "exit_code=!ERRORLEVEL!"
		exit /b !exit_code!
	)
	echo !CERT_DEPLOYER_LINE_PREFIX! : Restarting adb as root...
	call adb root > "!output_tmp_file!" 2>&1
	if !ERRORLEVEL! NEQ 0 ( 
		echo !CERT_DEPLOYER_LINE_PREFIX! : Error restarting the adb as root^^!
		echo !CERT_DEPLOYER_LINE_PREFIX! : The error is:
		for /F "usebackq delims=" %%I in ("!output_tmp_file!") do echo %%I 
		echo %CERT_DEPLOYER_LINE_PREFIX% : Please ensure that you have waited until the emulator home screen was displayed and that the emulator was running in your retry.
		exit %EXIT_RESTART_ADB_AS_ROOT_COMMAND_ERROR_CODE%
	)
	echo !CERT_DEPLOYER_LINE_PREFIX! : Restarted adb as root.

	echo !CERT_DEPLOYER_LINE_PREFIX! : Now disabling emulator secure boot verification for deploying the signed certificate to android system store...
	call adb shell avbctl disable-verification > "!output_tmp_file!" 2>&1
	if !ERRORLEVEL! NEQ 0 ( 
		echo !CERT_DEPLOYER_LINE_PREFIX! : Error disabling secure boot verification for deployment^^!
		echo !CERT_DEPLOYER_LINE_PREFIX! : The error is:
		for /F "usebackq delims=" %%I in ("!output_tmp_file!") do echo %%I 
		echo %CERT_DEPLOYER_LINE_PREFIX% : Please retry running ths script..
		exit %EXIT_DISABLE_SECURE_ROOT_COMMAND_ERROR_CODE%
	)
	echo !CERT_DEPLOYER_LINE_PREFIX! : Disabled emulator secure boot verification.

	echo !CERT_DEPLOYER_LINE_PREFIX! : Now rebooting adb...
	call adb reboot > "!output_tmp_file!" 2>&1
	if !ERRORLEVEL! NEQ 0 ( 
		echo !CERT_DEPLOYER_LINE_PREFIX! : Error rebooting^^!
		echo !CERT_DEPLOYER_LINE_PREFIX! : The error is:
		for /F "usebackq delims=" %%I in ("!output_tmp_file!") do echo %%I 
		echo %CERT_DEPLOYER_LINE_PREFIX% : Please retry running ths script.
		exit %EXIT_ADB_REBOOT_COMMAND_ERROR_CODE%
	)
	echo.
	echo !CERT_DEPLOYER_LINE_PREFIX! : Wait for the emulator to complete the reboot - until you see home screen popping up.
	echo.	
	set /p asd="%CERT_DEPLOYER_LINE_PREFIX% : Press any key to continue, when ready..."	
	echo.

	echo !CERT_DEPLOYER_LINE_PREFIX! : Restarting adb as root...
	call adb root > "!output_tmp_file!" 2>&1
	if !ERRORLEVEL! NEQ 0 ( 
		echo !CERT_DEPLOYER_LINE_PREFIX! : Error restarting the adb as root^^!
		echo !CERT_DEPLOYER_LINE_PREFIX! : The error is:
		for /F "usebackq delims=" %%I in ("!output_tmp_file!") do echo %%I 
		echo %CERT_DEPLOYER_LINE_PREFIX% : Please ensure that you have waited until the emulator home screen was displayed and that the emulator was running in your retry.
		exit %EXIT_RESTART_ADB_AS_ROOT_COMMAND_ERROR_CODE%
	)
	echo !CERT_DEPLOYER_LINE_PREFIX! : Restarted adb as root.

	echo !CERT_DEPLOYER_LINE_PREFIX! : Remounting android device partition for read-write...
	call adb remount > "!output_tmp_file!" 2>&1
	if !ERRORLEVEL! NEQ 0 ( 
		echo !CERT_DEPLOYER_LINE_PREFIX! : Error remounting android device partition for reading and writing^^!
		echo !CERT_DEPLOYER_LINE_PREFIX! : The error is:
		for /F "usebackq delims=" %%I in ("!output_tmp_file!") do echo %%I 
		echo %CERT_DEPLOYER_LINE_PREFIX% : Please retry running ths script.
		exit %EXIT_REMOUNT_PARTITIONS_COMMAND_ERROR_CODE%
	)
	echo !CERT_DEPLOYER_LINE_PREFIX! : Remounted android device parition for read-write.

	echo !CERT_DEPLOYER_LINE_PREFIX! : Now rebooting adb...
	call adb reboot > "!output_tmp_file!" 2>&1
	if !ERRORLEVEL! NEQ 0 ( 
		echo !CERT_DEPLOYER_LINE_PREFIX! : Error rebooting adb^^!
		echo !CERT_DEPLOYER_LINE_PREFIX! : The error is:
		for /F "usebackq delims=" %%I in ("!output_tmp_file!") do echo %%I 
		echo %CERT_DEPLOYER_LINE_PREFIX% : Please retry running ths script.
		exit %EXIT_ADB_REBOOT_COMMAND_ERROR_CODE%
	)
	echo.
	echo !CERT_DEPLOYER_LINE_PREFIX! : Wait for the emulator to complete the reboot - until you see home screen popping up.
	echo.	
	set /p asd="%CERT_DEPLOYER_LINE_PREFIX% : Press any key to continue, when ready..."	
	echo.

	echo !CERT_DEPLOYER_LINE_PREFIX! : Restarting adb as root...
	call adb root > "!output_tmp_file!" 2>&1
	if !ERRORLEVEL! NEQ 0 ( 
		echo !CERT_DEPLOYER_LINE_PREFIX! : Error restarting the adb as root^^!
		echo !CERT_DEPLOYER_LINE_PREFIX! : The error is:
		for /F "usebackq delims=" %%I in ("!output_tmp_file!") do echo %%I 
		echo %CERT_DEPLOYER_LINE_PREFIX% : Please ensure that you have waited until the emulator home screen was displayed and that the emulator was running in your retry.
		exit %EXIT_RESTART_ADB_AS_ROOT_COMMAND_ERROR_CODE%
	)
	echo !CERT_DEPLOYER_LINE_PREFIX! : Restarted adb as root.	

	echo !CERT_DEPLOYER_LINE_PREFIX! : Mounting android device partition after reboot...
	call adb remount > "!output_tmp_file!" 2>&1
	if !ERRORLEVEL! NEQ 0 ( 
		echo !CERT_DEPLOYER_LINE_PREFIX! : Error mounting android device partition for reading and writing^^!
		echo !CERT_DEPLOYER_LINE_PREFIX! : The error is:
		for /F "usebackq delims=" %%I in ("!output_tmp_file!") do echo %%I 
		echo %CERT_DEPLOYER_LINE_PREFIX% : Please retry running ths script.
		exit %EXIT_REMOUNT_PARTITIONS_COMMAND_ERROR_CODE%
	)
	echo !CERT_DEPLOYER_LINE_PREFIX! : Mounted android device partition for read-write after reboot.

	echo !CERT_DEPLOYER_LINE_PREFIX! : Pushing AppBrahma root CA signed server certiciate to Android emulator system store...
	call adb push !hash_named_cert!.0 /system/etc/security/cacerts > "!output_tmp_file!" 2>&1
	if !ERRORLEVEL! NEQ 0 ( 
		echo !CERT_DEPLOYER_LINE_PREFIX! : Error pushing the signed server certificate to android emulator system store^^!
		echo !CERT_DEPLOYER_LINE_PREFIX! : The error is:
		for /F "usebackq delims=" %%I in ("!output_tmp_file!") do echo %%I 
		echo %CERT_DEPLOYER_LINE_PREFIX% : Please retry running ths script.
		exit %EXIT_PUSH_SIGNED_CERT_COMMAND_ERROR_CODE%
	)
	echo !CERT_DEPLOYER_LINE_PREFIX! : Pushed AppBrahma root CA signed server certiciate to Android emulator system store.
	del /F !hash_named_cert!.0

	echo !CERT_DEPLOYER_LINE_PREFIX! : Setting the certificate permissions...
	call adb shell chmod 664 /system/etc/security/cacerts/!hash_named_cert!.0 > "!output_tmp_file!" 2>&1
	if !ERRORLEVEL! NEQ 0 ( 
		echo !CERT_DEPLOYER_LINE_PREFIX! : Error setting the permissions to the pushed server certificate in android emulator system store^^!
		echo !CERT_DEPLOYER_LINE_PREFIX! : The error is:
		for /F "usebackq delims=" %%I in ("!output_tmp_file!") do echo %%I 
		echo %CERT_DEPLOYER_LINE_PREFIX% : Please retry running ths script.
		exit %EXIT_PUSH_SIGNED_CERT_COMMAND_ERROR_CODE%
	)
	echo !CERT_DEPLOYER_LINE_PREFIX! : Certificate permissions set.

	echo !CERT_DEPLOYER_LINE_PREFIX! : Now rebooting adb...
	call adb reboot > "!output_tmp_file!" 2>&1
	if !ERRORLEVEL! NEQ 0 ( 
		echo !CERT_DEPLOYER_LINE_PREFIX! : Error rebooting adb^^!
		echo !CERT_DEPLOYER_LINE_PREFIX! : The error is:
		for /F "usebackq delims=" %%I in ("!output_tmp_file!") do echo %%I 
		echo %CERT_DEPLOYER_LINE_PREFIX% : Please retry running ths script.
		exit %EXIT_ADB_REBOOT_COMMAND_ERROR_CODE%
	)
	echo.
	echo !CERT_DEPLOYER_LINE_PREFIX! : Wait for the emulator to complete the reboot - until you see home screen popping up.
	echo.	
	set /p asd="%CERT_DEPLOYER_LINE_PREFIX% : Press any key to continue, when ready..."	
	echo.

	echo !CERT_DEPLOYER_LINE_PREFIX! : AppBrahma root CA signed server certificate is successfully deployed to Android emulator for testing Unimobile App with back-end AppBrahma web server.
	echo.
	echo !CERT_DEPLOYER_LINE_PREFIX! : Please be aware that if you close this emulator and re-open from outside this script for testing Unimobile app using HTTPS - it won't work due to the restrictions imposed by Android API leve security. Only way to test HTTPS communication with server for AppBrahma root CA signed server certificate or any other self-signed certificates is to go through this script and let the emulator run for the full testing session.
	echo.
	exit /b 0

:: cert deployment for sdk api level less than or equals 28
:cert_deployment_to_devices_leq_sdk_api_level_28
	call :signed_ca_cert_rename_for_android
	if !ERRORLEVEL! NEQ 0 ( 
		set "exit_code=!ERRORLEVEL!"
		exit /b !exit_code!
	)
	echo !CERT_DEPLOYER_LINE_PREFIX! : Restarting adb as root...
	call adb root > "!output_tmp_file!" 2>&1
	if !ERRORLEVEL! NEQ 0 ( 
		echo !CERT_DEPLOYER_LINE_PREFIX! : Error restarting the adb as root^^!
		echo !CERT_DEPLOYER_LINE_PREFIX! : The error is:
		for /F "usebackq delims=" %%I in ("!output_tmp_file!") do echo %%I 
		echo %CERT_DEPLOYER_LINE_PREFIX% : Please ensure that you have waited until the emulator home screen was displayed and that the emulator was running in your retry.
		exit %EXIT_RESTART_ADB_AS_ROOT_COMMAND_ERROR_CODE%
	)
	echo !CERT_DEPLOYER_LINE_PREFIX! : Restarted adb as root.	

	echo !CERT_DEPLOYER_LINE_PREFIX! : Remounting android emulator paritions as read-write...
	call adb remount > "!output_tmp_file!" 2>&1
	if !ERRORLEVEL! NEQ 0 ( 
		echo !CERT_DEPLOYER_LINE_PREFIX! : Error remounting android emulator paritions for reading and writing^^!
		echo !CERT_DEPLOYER_LINE_PREFIX! : The error is:
		for /F "usebackq delims=" %%I in ("!output_tmp_file!") do echo %%I 
		echo %CERT_DEPLOYER_LINE_PREFIX% : Please retry running ths script.
		exit %EXIT_REMOUNT_PARTITIONS_COMMAND_ERROR_CODE%
	)
	echo !CERT_DEPLOYER_LINE_PREFIX! : Remounted android emulator paritions as read-write.

	echo !CERT_DEPLOYER_LINE_PREFIX! : Now rebooting adb...
	call adb reboot > "!output_tmp_file!" 2>&1
	if !ERRORLEVEL! NEQ 0 ( 
		echo !CERT_DEPLOYER_LINE_PREFIX! : Error rebooting adb^^!
		echo !CERT_DEPLOYER_LINE_PREFIX! : The error is:
		for /F "usebackq delims=" %%I in ("!output_tmp_file!") do echo %%I 
		echo %CERT_DEPLOYER_LINE_PREFIX% : Please retry running ths script.
		exit %EXIT_ADB_REBOOT_COMMAND_ERROR_CODE%
	)
	echo.
	echo !CERT_DEPLOYER_LINE_PREFIX! : Wait for the emulator to complete the reboot - until you see home screen popping up.
	echo.	
	set /p asd="%CERT_DEPLOYER_LINE_PREFIX% : Press any key to continue, when ready..."	
	echo.

	echo !CERT_DEPLOYER_LINE_PREFIX! : Restarting adb as root...
	call adb root > "!output_tmp_file!" 2>&1
	if !ERRORLEVEL! NEQ 0 ( 
		echo !CERT_DEPLOYER_LINE_PREFIX! : Error restarting the adb as root^^!
		echo !CERT_DEPLOYER_LINE_PREFIX! : The error is:
		for /F "usebackq delims=" %%I in ("!output_tmp_file!") do echo %%I 
		echo %CERT_DEPLOYER_LINE_PREFIX% : Please ensure that you have waited until the emulator home screen was displayed and that the emulator was running in your retry.
		exit %EXIT_RESTART_ADB_AS_ROOT_COMMAND_ERROR_CODE%
	)
	echo !CERT_DEPLOYER_LINE_PREFIX! : Restarted adb as root.	

	echo !CERT_DEPLOYER_LINE_PREFIX! : Mounting android emulator paritions after reboot...
	call adb remount > "!output_tmp_file!" 2>&1
	if !ERRORLEVEL! NEQ 0 ( 
		echo !CERT_DEPLOYER_LINE_PREFIX! : Error mounting android emulator paritions for reading and writing^^!
		echo !CERT_DEPLOYER_LINE_PREFIX! : The error is:
		for /F "usebackq delims=" %%I in ("!output_tmp_file!") do echo %%I 
		echo %CERT_DEPLOYER_LINE_PREFIX% : Please retry running ths script.
		exit %EXIT_REMOUNT_PARTITIONS_COMMAND_ERROR_CODE%
	)
	echo !CERT_DEPLOYER_LINE_PREFIX! : Mounted android emulator paritions as read-write after reboot.

	echo !CERT_DEPLOYER_LINE_PREFIX! : Pushing AppBrahma root CA signed server certiciate to Android emulator system store...
	call adb push !hash_named_cert!.0 /system/etc/security/cacerts > "!output_tmp_file!" 2>&1
	if !ERRORLEVEL! NEQ 0 ( 
		echo !CERT_DEPLOYER_LINE_PREFIX! : Error pushing the signed server certificate to android emulator system store^^!
		echo !CERT_DEPLOYER_LINE_PREFIX! : The error is:
		for /F "usebackq delims=" %%I in ("!output_tmp_file!") do echo %%I 
		echo %CERT_DEPLOYER_LINE_PREFIX% : Please retry running ths script.
		exit %EXIT_PUSH_SIGNED_CERT_COMMAND_ERROR_CODE%
	)
	echo !CERT_DEPLOYER_LINE_PREFIX! : Pushed AppBrahma root CA signed server certiciate to Android emulator system store.
	del /F !hash_named_cert!.0

	echo !CERT_DEPLOYER_LINE_PREFIX! : Setting the certificate permissions...
	call adb shell chmod 664 /system/etc/security/cacerts/!hash_named_cert!.0 > "!output_tmp_file!" 2>&1
	if !ERRORLEVEL! NEQ 0 ( 
		echo !CERT_DEPLOYER_LINE_PREFIX! : Error setting the permissions to the pushed server certificate in android emulator system store^^!
		echo !CERT_DEPLOYER_LINE_PREFIX! : The error is:
		for /F "usebackq delims=" %%I in ("!output_tmp_file!") do echo %%I 
		echo %CERT_DEPLOYER_LINE_PREFIX% : Please retry running ths script.
		exit %EXIT_PUSH_SIGNED_CERT_COMMAND_ERROR_CODE%
	)
	echo !CERT_DEPLOYER_LINE_PREFIX! : Certificate permissions set.

	echo !CERT_DEPLOYER_LINE_PREFIX! : Now rebooting adb...
	call adb reboot > "!output_tmp_file!" 2>&1
	if !ERRORLEVEL! NEQ 0 ( 
		echo !CERT_DEPLOYER_LINE_PREFIX! : Error rebooting adb^^!
		echo !CERT_DEPLOYER_LINE_PREFIX! : The error is:
		for /F "usebackq delims=" %%I in ("!output_tmp_file!") do echo %%I 
		echo %CERT_DEPLOYER_LINE_PREFIX% : Please retry running ths script.
		exit %EXIT_ADB_REBOOT_COMMAND_ERROR_CODE%
	)
	echo.
	echo !CERT_DEPLOYER_LINE_PREFIX! : Wait for the emulator to complete the reboot - until you see home screen popping up.
	echo.	
	set /p asd="%CERT_DEPLOYER_LINE_PREFIX% : Press any key to continue, when ready..."	
	echo.

	echo !CERT_DEPLOYER_LINE_PREFIX! : AppBrahma root CA signed server certificate is successfully deployed to Android emulator for testing Unimobile App with back-end AppBrahma web server.
	echo.
	echo !CERT_DEPLOYER_LINE_PREFIX! : Please be aware that if you close this emulator and re-open from outside this script for testing Unimobile app using HTTPS - it won't work due to the restrictions imposed by Android API leve security. Only way to test HTTPS communication with server for AppBrahma root CA signed server certificate or any other self-signed certificates is to go through this script and let the emulator run for the full testing session.
	echo.
	exit /b 0

:: function to rename/generate hashnamed cert file for android deployment
:signed_ca_cert_rename_for_android
	echo %CERT_DEPLOYER_LINE_PREFIX% : Preparing the certificate for deploying...
	set "first_line_string="
	set "first_line=1"
	call openssl x509 -inform PEM -subject_hash_old -in appbrahma-root-ca-signed-server.crt > "!output_tmp_file!" 2>&1
	if !ERRORLEVEL! NEQ 0 ( 
		echo !CERT_DEPLOYER_LINE_PREFIX! : Error generating hash of the certificate needed to deploy^^!
		echo !CERT_DEPLOYER_LINE_PREFIX! : The error is:
		for /F "usebackq delims=" %%I in ("!output_tmp_file!") do echo %%I 
		echo %CERT_DEPLOYER_LINE_PREFIX% : Please fix above errors and retry running this script.
		exit %EXIT_CERT_HASH_GEN_COMMAND_ERROR_CODE%
	)
	for /F "tokens=*" %%G in (!output_tmp_file!) do (	
		if !first_line! EQU 1 (
			set "first_line_string=%%G"
			set /a first_line=!first_line!+1
		)	
	)	
	if !first_line_string! == "" (
		echo !CERT_DEPLOYER_LINE_PREFIX! : Error generating hash of the certificate needed to deploy^^!
		echo !CERT_DEPLOYER_LINE_PREFIX! : Hashcode of the certificate is empty or null^^!
		echo %CERT_DEPLOYER_LINE_PREFIX% : Please retry running this script.
		exit %EXIT_CERT_HASH_GEN_COMMAND_ERROR_CODE%
	)
	set "hash_named_cert=!first_line_string!"
	echo %CERT_DEPLOYER_LINE_PREFIX% : Generated hashcode is !hash_named_cert!.

	call copy /y !signed_cert_name! !hash_named_cert!.0 > "!output_tmp_file!" 2>&1
	if !ERRORLEVEL! NEQ 0 ( 
		echo !CERT_DEPLOYER_LINE_PREFIX! : Error preparing the certificate for the deployment^^!
		echo !CERT_DEPLOYER_LINE_PREFIX! : The error is:
		for /F "usebackq delims=" %%I in ("!output_tmp_file!") do echo %%I 
		echo %CERT_DEPLOYER_LINE_PREFIX% : Please fix above errors and retry running this script.
		exit %EXIT_CERT_HASH_GEN_COMMAND_ERROR_CODE%
	)
	echo !CERT_DEPLOYER_LINE_PREFIX! : Prepared the server Appbrahma root CA signed server certificate for android device deployment.
	exit /b !exit_code!

:: node dependencies install, ionic build, and add capacitor platform function
:unimo_install_ionic_deps_build_and_platform
	setlocal EnableDelayedExpansion		
	if !cap_android_platform_reinstall! EQU 0 (
		echo %MOBILE_GENERATOR_LINE_PREFIX% : Now installing node dependencies...
		call :npm_install	
		if !ERRORLEVEL! NEQ 0 ( 
			echo %MOBILE_GENERATOR_LINE_PREFIX% : Error installing node dependencies^^!
			echo %MOBILE_GENERATOR_LINE_PREFIX% : Error details are displayed below. Please fix these issues and re-run this script.
			for /F "usebackq delims=" %%I in ("!output_tmp_file!") do echo %%I 
			set "exit_code=!ERRORLEVEL!"
			exit /b !exit_code! 
		)			
		echo %MOBILE_GENERATOR_LINE_PREFIX% : Installed node dependencies.
		
		echo %MOBILE_GENERATOR_LINE_PREFIX% : Now building the project...
		call :ionic_build
		if !ERRORLEVEL! NEQ 0 ( 
			echo %MOBILE_GENERATOR_LINE_PREFIX% : Error building the project^^!
			echo %MOBILE_GENERATOR_LINE_PREFIX% : Error details are displayed below. Please fix these issues and re-run this script.
			for /F "usebackq delims=" %%I in ("!output_tmp_file!") do echo %%I 
			set "exit_code=!ERRORLEVEL!"
			exit /b !exit_code!		
		)	
		echo %MOBILE_GENERATOR_LINE_PREFIX% : Project built successfully.
	)			
	
	echo %MOBILE_GENERATOR_LINE_PREFIX% : Now installing capacitor Android platform...
	call :add_cap_platform	
	if !ERRORLEVEL! NEQ 0 ( 
		if !ERRORLEVEL! EQU %EXIT_IONIC_RE_RUN_INSTALL_AND_BUILD% (
			set /A cap_android_platform_reinstall=1
			echo %MOBILE_GENERATOR_LINE_PREFIX% : Preparing to re-install Android capacitor platform...											
			call :unimo_install_ionic_deps_build_and_platform 
			if !ERRORLEVEL! NEQ 0 ( 
				echo %MOBILE_GENERATOR_LINE_PREFIX% : Error re-installing dependencies for re-installing Android capacitor^^!
				echo %MOBILE_GENERATOR_LINE_PREFIX% : Error details are displayed below. Please fix these issues and re-run this script.
				for /F "usebackq delims=" %%I in ("!output_tmp_file!") do echo %%I 
				set "exit_code=!ERRORLEVEL!"
				exit /b !exit_code!		
			) else (				
				exit /b 0	
			)						
		) else (
			echo %MOBILE_GENERATOR_LINE_PREFIX% : Error installing android capacitor platform^^!
			echo %MOBILE_GENERATOR_LINE_PREFIX% : Error details are displayed below. Please fix these issues and re-run this script.
			for /F "usebackq delims=" %%I in ("!output_tmp_file!") do echo %%I 			
			exit /b %EXIT_IONIC_CAP_ADD_PLATFORM_COMMAND_ERROR_CODE%
		)		
	) else (
		echo %MOBILE_GENERATOR_LINE_PREFIX% : Installed capacitor Android platform.
		exit /b 0
	)	
	set "exit_code=!ERRORLEVEL!"
	exit /b !exit_code!

:npm_install
	setlocal EnableDelayedExpansion	
	:: echo %MOBILE_GENERATOR_LINE_PREFIX% : Installing nodejs dependencies...			
	call npm install > "!output_tmp_file!" 2>&1
	if !ERRORLEVEL! NEQ 0 (
		echo %MOBILE_GENERATOR_LINE_PREFIX% : Error installing nodejs dependencies^!
		echo %MOBILE_GENERATOR_LINE_PREFIX% : Fixing the errors...
		call rmdir /S /Q "node_modules" > "!output_tmp_file!" 2>&1			
		if !ERRORLEVEL! NEQ 0  (
			echo %MOBILE_GENERATOR_LINE_PREFIX% : Error removing node_modules for fixing dependencies install errors^^!	
			echo %MOBILE_GENERATOR_LINE_PREFIX% : Error details are displayed below. Aborting the execution.
			echo %MOBILE_GENERATOR_LINE_PREFIX% : Please retry running the script after fixing these reported errors.			
			for /F "usebackq delims=" %%I in ("!output_tmp_file!") do echo %%I 								
			exit /b %EXIT_NPM_INSTALL_COMMAND_ERROR_CODE%
		) else (				
			:: echo %MOBILE_GENERATOR_LINE_PREFIX% : Fixing nodejs dependencies installation errors.
			call :npm_reinstall
			if !ERRORLEVEL! NEQ 0 (
				set "exit_code=!ERRORLEVEL!"
				exit /b !exit_code!
			) else (
				exit /b 0
			)
		)			
	) else (		
		exit /b 0
	)	
	set "exit_code=!ERRORLEVEL!"
	exit /b !exit_code!

:npm_reinstall	
	setlocal EnableDelayedExpansion	
	call npm install  > "!output_tmp_file!" 2>&1
	if !ERRORLEVEL! NEQ 0 (
		echo %MOBILE_GENERATOR_LINE_PREFIX% : Re-attempt to install nodejs dependencies resulted in error^^!
		echo %MOBILE_GENERATOR_LINE_PREFIX% : Error details are displayed below. Aborting Unimobile build and run process.
		echo %MOBILE_GENERATOR_LINE_PREFIX% : Please retry running this script after fixing these issues.		
		for /F "usebackq delims=" %%I in ("!output_tmp_file!") do echo %%I 		
		exit /b %EXIT_NPM_INSTALL_COMMAND_ERROR_CODE%		
	) else ( 		
		exit /b 0
	)
	exit /b !ERRORLEVEL!		

:ionic_build
	setlocal EnableDelayedExpansion	
	call ionic build > "!output_tmp_file!" 2>&1
	if !ERRORLEVEL! NEQ 0 (
		echo %MOBILE_GENERATOR_LINE_PREFIX% : Error building the project^^!
		echo %MOBILE_GENERATOR_LINE_PREFIX% : Error details are displayed below. Aborting Unimobile build and run process.		
		echo %MOBILE_GENERATOR_LINE_PREFIX% : Please retry running the script after fixing these reported errors.
		for /F "usebackq delims=" %%I in ("!output_tmp_file!") do echo %%I 		
		exit /b %EXIT_IONIC_BUILD_COMMAND_ERROR_CODE%
	) else ( 		
		exit /b 0
	)
	exit /b !ERRORLEVEL!
	
:add_cap_platform
	setlocal EnableDelayedExpansion		
	set "for_exec_result="		
	call ionic capacitor add android > "!output_tmp_file!" 2>&1
	if !ERRORLEVEL! NEQ 0 (
		echo %MOBILE_GENERATOR_LINE_PREFIX% : It appears Android capacitor platform was already installed or installed nodejs dependencies are incomptabile^^!		
		echo %MOBILE_GENERATOR_LINE_PREFIX% : For avoiding run-time errors, re-installing android platform.
		:: call rmdir /S /Q "android" "www" "node_modules" > "!output_tmp_file!" 2>&1			
		call rmdir /S /Q "android" > "!output_tmp_file!" 2>&1			
		if !ERRORLEVEL! NEQ 0  (
			echo %MOBILE_GENERATOR_LINE_PREFIX% : Error removing android directory for re-installig Android platform^^!	
			echo %MOBILE_GENERATOR_LINE_PREFIX% : Error details are displayed below. Aborting the execution.
			for /F "usebackq delims=" %%I in ("!output_tmp_file!") do echo %%I 					
			echo %MOBILE_GENERATOR_LINE_PREFIX% : Please retry running the script after fixing these reported errors.			
			exit /b %EXIT_IONIC_CAP_ADD_PLATFORM_COMMAND_ERROR_CODE%
		) else (				
			echo %MOBILE_GENERATOR_LINE_PREFIX% : Removed android platform.
			exit /b %EXIT_IONIC_RE_RUN_INSTALL_AND_BUILD%			
		)	
	) else (		
		exit /b 0		
	)
	set "exit_code=!ERRORLEVEL!"
	exit /b !exit_code!

:: End of the script
