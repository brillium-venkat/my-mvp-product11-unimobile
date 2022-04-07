#!/bin/bash
# ====================================================================================================================================
# appbrahma-build-and-run-android.sh
# AppBrahma Android Unimobile App building and running
# Created by Venkateswar Reddy Melachervu on 16-11-2021.
# Updates:
#      17-12-2021 - Added gracious error handling and recovery mechansim for already added android platform
#      26-12-2021 - Added error handling and android sdk path check
#      20-01-2022 - Created script for linux
#      29-01-2022 - Updated
#      27-02-2022 - Updated for streamlining exit error codes and re-organizing build code into a function for handling 
#                   dependency version incompatibilities
#      07-03-2022 - Updated for function exit codes, format and app display prefix
#      08-03-2022 - Synchronized with windows batch ejs file
#      12-03-2022 - Updated for installation checks and de-cluttering the console output by capturing the output into env variable
#	   27-03-2022 - Unified http and https script files into one
#
#      Reference article - https://docs.mitmproxy.org/stable/howto-install-system-trusted-ca-android/
# ===================================================================================================================================================

# Required version values
MOBILE_GENERATOR_NAME=UniBrahma
CERT_DEPLOYER="Unimobile Cert Deployer"
MOBILE_GENERATOR_LINE_PREFIX=\[$MOBILE_GENERATOR_NAME]
CERT_DEPLOYER_LINE_PREFIX=\[$CERT_DEPLOYER]
#macos related
OS_MAJOR_VERSION=10
OS_MINOR_VERSION=0
OS_PATCH_VERSION=1

NODE_MAJOR_VERSION=16
NPM_MAJOR_VERSION=6
IONIC_CLI_MAJOR_VERSION=6
IONIC_CLI_MINOR_VERSION=16
JAVA_MIN_MAJOR_VERSION=11
JAVA_MIN_MINOR_VERSION=0

# cert deployment related
EXIT_CERT_DEPLOYER_EXIT_CODE_BASE=150
EXIT_ADB_EMULATOR_PATHS_ERROR=151
EXIT_COMMAND_ERROR_CODE=152
EXIT_ANDROID_HOME_PATH_COMMAND_ERROR_CODE=153
EXIT_ADB_DEV_LIST_COMMAND_ERROR_CODE=154
EXIT_EMULATOR_HELP_COMMAND_ERROR_CODE=155
EXIT_ADB_HELP_COMMAND_ERROR_CODE=156
EXIT_EMULATOR_LIST_AVDS_HELP_COMMAND_ERROR_CODE=157
EXIT_ADB_LIST_DEVICES_HELP_COMMAND_ERROR_CODE=158
EXIT_NO_DEVICE_CONNECTED_ERROR_CODE=159
EXIT_OPENSSL_NOT_IN_PATH_ERROR_CODE=160
EXIT_CERT_HASH_GEN_COMMAND_ERROR_CODE=161
EXIT_RUN_EMULATOR_COMMAND_ERROR_CODE=162
EXIT_RESTART_ADB_AS_ROOT_COMMAND_ERROR_CODE=163
EXIT_DISABLE_SECURE_ROOT_COMMAND_ERROR_CODE=164
EXIT_ADB_REBOOT_COMMAND_ERROR_CODE=165
EXIT_REMOUNT_PARTITIONS_COMMAND_ERROR_CODE=166
EXIT_PUSH_SIGNED_CERT_COMMAND_ERROR_CODE=167
EXIT_SET_CERT_PERMS_COMMAND_ERROR_CODE=168

# build and run related
EXIT_ERROR_CODE=200
EXIT_WINDOWS_VERSION_CHECK_COMMAND_ERROR_CODE=201
EXIT_NODE_VERSION_CHECK_COMMAND_ERROR_CODE=202
EXIT_NPM_VERSION_CHECK_COMMAND_ERROR_CODE=203
EXIT_IONIC_CLI_VERSION_CHECK_COMMAND_ERROR_CODE=204
EXIT_JAVA_VERSION_CHECK_COMMAND_ERROR_CODE=205
EXIT_JDK_VERSION_CHECK_COMMAND_ERROR_CODE=206
EXIT_EMULATOR_HELP_COMMAND_ERROR_CODE=207
EXIT_NPM_INSTALL_COMMAND_ERROR_CODE=208
EXIT_IONIC_BUILD_COMMAND_ERROR_CODE=209
EXIT_IONIC_CAP_ADD_PLATFORM_COMMAND_ERROR_CODE=210
EXIT_UNIMO_INSTALL_BUILD_ERROR_CODE=211
EXIT_IONIC_RE_RUN_INSTALL_AND_BUILD=212
EXIT_CORDOVA_RES_COMMAND_INSTALL_ERROR_CODE=213
EXIT_CORDOVA_RES_COMMAND_ERROR_CODE=214
EXIT_ADB_VERSION_COMMAND_ERROR_CODE=215
EXIT_IONIC_CAP_RUN_COMMAND_ERROR_CODE=216
EXIT_GET_SDK_API_LEVEL_ERROR_CODE=217
EXIT_ADB_REVERSE_COMMAND_ERROR_CODE=218
EXIT_WRONG_PARAMS_ERROR_CODE=219
EXIT_EMULATOR_LIST_AVDS_COMMAND_ERROR_CODE=220
EXIT_PROJ_REBUILD_ERROR_CODE=221
EXIT_PRE_REQ_CHECK_FAILURE_CODE=222
EXIT_CERT_DEPLOYMENT_PRE_REQ_CHECK_FAILURE_CODE=223
EXIT_CERT_DEPLOYMENT_FAILURE_CODE=224
EXIT_ANDROID_HOME_NOT_SET_CODE=225
EXIT_EMULATOR_EXE_PATH_NOT_PROPERLY_SET_CODE=226
EXIT_ANDROID_PLATFORM_TOOLS_NOT_IN_PATH_CODE=227
EXIT_ANDROID_SDK_TOOLS_NOT_SET_IN_PATH_CODE=228
EXIT_ANDROID_SDK_PATH_NOT_SET_IN_PATH_CODE=229
EXIT_IONIC_REINSTALL_CAP_ANDROID_PLATFORM=230
EXIT_CORDOVA_RES_ICON_CUSTOMIZE_ERROR_CODE=231
EXIT_IONIC_CAP_ANDROID_RUN_COMMAND_ERROR_CODE=232
EXIT_ADB_REVERSE_TCP_COMMAND_ERROR_CODE=233


APPBRAHMA_CERT_DEPLOYMENT=1
THIRD_PARTY_CERT_DEPLOYED=2
INVALID_CERT_ISSUER_SELECTION=3
cap_android_platform_reinstall=0
target=""

# arguments and globals init
build_rebuild=$1
server_rest_api_mode=$2
expected_arg_count=2
build_type_all=0
build_type_android_platform_reinstall=1
build_type_redo_deps_build_cap_android_platform=2
unimo_build_type=$build_type_all
third_party_cert=0

# function common pre-reqs check
unimo_common_pre_reqs_validation() {
	return_code=0
	# OS version validation
	echo "$MOBILE_GENERATOR_LINE_PREFIX : Your MacOS version is : $(/usr/bin/sw_vers -productVersion)"
	# Minimum version required is Big Sur - 11.0.1 due to Xcode 12+ requirement for ionic capacitor
	if [[ $(/usr/bin/sw_vers -productVersion | awk -F. '{ print $1 }') -ge $OS_MAJOR_VERSION ]]; then
		if [[ $(/usr/bin/sw_vers -productVersion | awk -F. '{ print $2 }') -ge $OS_MINOR_VERSION ]]; then
			if [[ $(/usr/bin/sw_vers -productVersion | awk -F. '{ print $3 }') -ge $OS_PATCH_VERSION ]]; then
				echo "$MOBILE_GENERATOR_LINE_PREFIX : MacOS version requirement - $OS_MAJOR_VERSION.$OS_MINOR_VERSION.$OS_PATCH_VERSION - met, moving ahead with other checks..."
			else
				echo "$MOBILE_GENERATOR_LINE_PREFIX : You are running non-supported MacOS version $(/usr/bin/sw_vers -productVersion) for building and running AppBrahma generated Unimobile application project sources!"
				echo "$MOBILE_GENERATOR_LINE_PREFIX : Minimum required version is $OS_MAJOR_VERSION.$OS_MINOR_VERSION.$OS_PATCH_VERSION"
				echo "$MOBILE_GENERATOR_LINE_PREFIX : Aborting the build process. Please retry after ensuring pre-requisites are met."
				exit $EXIT_MACOS_VERSION_CHECK_COMMAND_ERROR_CODE
			fi
		else
			echo "$MOBILE_GENERATOR_LINE_PREFIX : You are running non-supported MacOS version $(/usr/bin/sw_vers -productVersion) for building and running AppBrahma generated Unimobile application project sources!"
			echo "$MOBILE_GENERATOR_LINE_PREFIX : Minimum required version is $OS_MAJOR_VERSION.$OS_MINOR_VERSION.$OS_PATCH_VERSION"
			echo "$MOBILE_GENERATOR_LINE_PREFIX : Aborting the build process. Please retry after ensuring pre-requisites are met."
			exit $EXIT_MACOS_VERSION_CHECK_COMMAND_ERROR_CODE
		fi
	else
		echo "$MOBILE_GENERATOR_LINE_PREFIX : You are running non-supported MacOS version $(/usr/bin/sw_vers -productVersion) for building and running AppBrahma generated Unimobile application project sources!"
		echo "$MOBILE_GENERATOR_LINE_PREFIX : Minimum required version is $OS_MAJOR_VERSION.$OS_MINOR_VERSION.$OS_PATCH_VERSION"
		echo "$MOBILE_GENERATOR_LINE_PREFIX : Aborting the build process. Please retry after ensuring pre-requisites are met."
		exit $EXIT_MACOS_VERSION_CHECK_COMMAND_ERROR_CODE
	fi

	# Node install check
	node_command=$(node --version 2>&1)
	if [ $? -gt 0 ]; then
		echo "$MOBILE_GENERATOR_LINE_PREFIX : Nodejs is not installed or NOT in PATH!"
		echo "$MOBILE_GENERATOR_LINE_PREFIX : Please install a stable and LTS version of nodejs major release $NODE_MAJOR_VERSION or fix the PATH and retry running this script."    
		return_code=$EXIT_NODE_VERSION_CHECK_COMMAND_ERROR_CODE
		return
	fi

	# Node version check
	node_version=$(node --version | awk -F. '{ print $1 }' 2>&1)
	# remove the first character
	node_command=${node_version#?}
	if [ $node_command -lt $NODE_MAJOR_VERSION ]; then
		echo "$MOBILE_GENERATOR_LINE_PREFIX : You are running non-supported nodejs major version $(node --version | awk -F. '{ print $1 }')!"
		echo "$MOBILE_GENERATOR_LINE_PREFIX : Minimum required version is $NODE_MAJOR_VERSION+"
		echo "$MOBILE_GENERATOR_LINE_PREFIX : Aborting the build process. Please install a stable and LTS NodeJS version of major release $NODE_MAJOR_VERSION+ and retry running this script."    
		return_code=$EXIT_NODE_VERSION_CHECK_COMMAND_ERROR_CODE
		return 
	else
	    	echo "$MOBILE_GENERATOR_LINE_PREFIX : Nodejs major version requirement - $NODE_MAJOR_VERSION - met, moving ahead with other checks..."
	fi

	# npm install check
	npm_command=$(npm --version 2>&1)
	if [ $? -gt 0 ]; then
		    echo "$MOBILE_GENERATOR_LINE_PREFIX : npm (Node Package Manager) is not installed or NOT in PATH!"
		    echo "$MOBILE_GENERATOR_LINE_PREFIX : Please install a stable and LTS version of npm major release $NPM_MAJOR_VERSION+ and retry running this script."    
		    return_code=$EXIT_NPM_VERSION_CHECK_COMMAND_ERROR_CODE
		    return 
	fi
	# NPM version check
	npm_version=$(npm --version | awk -F. '{ print $1 }' 2>&1)
	if [ $npm_version -lt $NPM_MAJOR_VERSION ]; then
		echo "$MOBILE_GENERATOR_LINE_PREFIX : You are running non-supported NPM major version $(npm --version | awk -F. '{ print $1 }')!"
		echo "$MOBILE_GENERATOR_LINE_PREFIX : Minimum required major NPM version is $NPM_MAJOR_VERSION+"
		echo "$MOBILE_GENERATOR_LINE_PREFIX : Aborting the build process. Please install a stable and LTS NPM version of major release $NPM_MAJOR_VERSION+ and retry running this script."
		return_code=$EXIT_NPM_VERSION_CHECK_COMMAND_ERROR_CODE
		return
	else
	    	echo "$MOBILE_GENERATOR_LINE_PREFIX : NPM major version requirement - $NPM_MAJOR_VERSION - met, moving ahead with other checks..."
	fi

	# ionic install check
	ionic_command=$(ionic --version 2>&1)
	if [ $? -gt 0 ]; then
	    echo "$MOBILE_GENERATOR_LINE_PREFIX : Ionic CLI is not installed or not in PATH!"
	    echo "$MOBILE_GENERATOR_LINE_PREFIX : Please install a stable and LTS version of ionic cli major release $NPM_MAJOR_VERSION+ and retry running this script."    
	    return_code=$EXIT_IONIC_CLI_VERSION_CHECK_COMMAND_ERROR_CODE
	    return
	fi
	# ionic cli version validation
	ionic_cli_version=$(ionic --version | awk -F. '{ print $1 }')
	if [ $ionic_cli_version -lt $IONIC_CLI_MAJOR_VERSION ]; then
	    echo "$MOBILE_GENERATOR_LINE_PREFIX : You are running non-supported Ionic CLI major version $ionic_cli_version!"
	    echo "$MOBILE_GENERATOR_LINE_PREFIX : Minimum required Ionic CLI major version is $IONIC_CLI_MAJOR_VERSION+"
	    echo "$MOBILE_GENERATOR_LINE_PREFIX : Aborting the build process. Please install a stable and LTS Ionic CLI version of major release $IONIC_CLI_MAJOR_VERSION+ and retry running this script."
	    return_code=$EXIT_IONIC_CLI_VERSION_CHECK_COMMAND_ERROR_CODE
	    return
	else
	    echo "$MOBILE_GENERATOR_LINE_PREFIX : Ionic CLI major version requirement - $IONIC_CLI_MAJOR_VERSION - met, moving ahead with other checks..."
	fi

	# java install check
	java_command=$(java -version 2>&1)
	if [ $? -gt 0 ]; then
	    echo "$MOBILE_GENERATOR_LINE_PREFIX : Java (JDK and runtime) is not installed or NOT in PATH!"
	    echo "$MOBILE_GENERATOR_LINE_PREFIX : Please install a stable and LTS Java JDK version of major release $JAVA_MIN_MAJOR_VERSION+ and retry running this script."    
	    return_code=$EXIT_JAVA_VERSION_CHECK_COMMAND_ERROR_CODE
	    return
	fi

	# java runtime version check
	java_version_first_part=$(java -version 2>&1 | awk 'NR==1 {print $3}'| awk -F. '{print $1}')
	java_version_first_part=$(echo $java_version_first_part | sed "s/\"//g")
	java_version_second_part=$(java -version 2>&1 | awk 'NR==1 {print $3}'| awk -F. '{print $2}')
	if [ $java_version_first_part -lt $JAVA_MIN_MAJOR_VERSION -a $java_version_second_part -lt $JAVA_MIN_MAJOR_VERSION ]; then
	    echo "$MOBILE_GENERATOR_LINE_PREFIX : You are running non-supported Java version $java_version_second_part!"
	    echo "$MOBILE_GENERATOR_LINE_PREFIX : Minimum required version is $JAVA_MIN_MAJOR_VERSION+"
	    echo "$MOBILE_GENERATOR_LINE_PREFIX : Aborting the build process. Please install a stable and LTS java release of major version $JAVA_MIN_MAJOR_VERSION and retry running this script."
	    return_code=$EXIT_JAVA_VERSION_CHECK_COMMAND_ERROR_CODE
	    return
	else
	    echo "$MOBILE_GENERATOR_LINE_PREFIX : Java version requirement - $JAVA_MIN_MAJOR_VERSION - met, moving ahead with other checks..."
	fi

	# jdk install check
	jdk_command=$(javac -help 2>&1)
	if [ $? -gt 0 ]; then
	    echo "$MOBILE_GENERATOR_LINE_PREFIX : Java JDK is not installed or NOT in PATH!"
	    echo "$MOBILE_GENERATOR_LINE_PREFIX : Please install a stable and LTS Java JDK version of major release $JAVA_MIN_MAJOR_VERSION+ and retry running this script."    
	    return_code=$EXIT_JDK_VERSION_CHECK_COMMAND_ERROR_CODE
	    return
	fi
	
	# android environment variables check - android_home, platform-tools, emulator, tools\bin
	android_home=$(echo $ANDROID_HOME | grep -iF "android/sdk" 2>&1)
	if [ $? -gt 0 ]; then
		echo "$MOBILE_GENERATOR_LINE_PREFIX : ANDROID_HOME environment varible is not set!"
		echo "$MOBILE_GENERATOR_LINE_PREFIX : Please set this variable value - usually $HOME//Android/Sdk - and retry running this script."
		return_code=$EXIT_ANDROID_HOME_NOT_SET_CODE
		return
	fi
	android_sdk_path=$(echo $PATH | grep -iF "android/sdk" 2>&1)
	if [ $? -gt 0 ]; then
		echo "$MOBILE_GENERATOR_LINE_PREFIX : Android SDK path is NOT set in PATH environment variable!"
		echo "$MOBILE_GENERATOR_LINE_PREFIX : Please set this path value - usually $HOME/Android/Sdk - and retry running this script."
		return_code=$EXIT_ANDROID_SDK_PATH_NOT_SET_IN_PATH_CODE
		return
	fi
	android_sdk_platform_tools_path=$(echo $PATH | grep -iF "android/sdk/platform-tools" 2>&1)
	if [ $? -gt 0 ]; then
		echo "$MOBILE_GENERATOR_LINE_PREFIX : Android SDK Platform tools path is NOT set in PATH environment variable!"
		echo "$MOBILE_GENERATOR_LINE_PREFIX : Please set this path value - usually $HOME/Android/Sdk/platform-tools - and retry running this script."
		return_code=$EXIT_ANDROID_PLATFORM_TOOLS_NOT_IN_PATH_CODE
		return
	fi
	android_emulator_path=$(echo $PATH | grep -iF "android/sdk/emulator" 2>&1)
	if [ $? -gt 0 ]; then
		emu_path=$(which emulator)
		if [[ $? -ne 0 ]]; then
			echo "$MOBILE_GENERATOR_LINE_PREFIX : Currently Android emulator executable path is NOT set in PATH environment variable!"			
			echo "$MOBILE_GENERATOR_LINE_PREFIX : Usually the relevant path is $HOME/Android/Sdk/emulator/emulator"
			echo "$MOBILE_GENERATOR_LINE_PREFIX : Please set the relevant emulator path in PATH and retry running this script."
			return_code=$EXIT_EMULATOR_EXE_PATH_NOT_PROPERLY_SET_CODE
		else
			echo "$MOBILE_GENERATOR_LINE_PREFIX : Currently Android emulator executable path is set to $emu_path in PATH environment variable which is not relevant for this script"			
			echo "$MOBILE_GENERATOR_LINE_PREFIX : Usually the relevant path is $HOME/Android/Sdk/emulator/emulator"
			echo "$MOBILE_GENERATOR_LINE_PREFIX : Please set the relevant emulator path in PATH and retry running this script."
			return_code=$EXIT_EMULATOR_EXE_PATH_NOT_PROPERLY_SET_CODE
		fi		
		return
	fi
	android_sdk_tools_path=$(echo $PATH | grep -iF "android/sdk/tools/bin" 2>&1)
	if [ $? -gt 0 ]; then
		echo "$MOBILE_GENERATOR_LINE_PREFIX : Android SDK tools path is NOT set in PATH environment variable!"
		echo "$MOBILE_GENERATOR_LINE_PREFIX : Please set this path value - usually $HOME/Android/Sdk/tools/bin - and retry running this script."
		return_code=$EXIT_ANDROID_SDK_TOOLS_NOT_SET_IN_PATH_CODE
		return
	fi
	#android_emulator_whereis_path=$(whereis emulator | grep -iF "android/sdk/emulator/emulator" 2>&1)
	#if [ $? -gt 0 ]; then
	#	echo "$MOBILE_GENERATOR_LINE_PREFIX : Android emulator path is NOT set properly in PATH environment variable!"
	#	echo "$MOBILE_GENERATOR_LINE_PREFIX : Currently path is : $android_emulator_whereis_path"
	#	echo "$MOBILE_GENERATOR_LINE_PREFIX : Please set this path value - usually $HOME/Android/Sdk/emulator/emulator - and retry running this script."
	#	return_code=$EXIT_EMULATOR_EXE_PATH_NOT_PROPERLY_SET_CODE
	#	return
	#fi
	# adb command check
	android_adb_command_check=$(adb --version 2>&1)
	if [ $? -gt 0 ]; then
		echo "$MOBILE_GENERATOR_LINE_PREFIX : adb command executable path is not found. Either Android SDK tools not installed or adb executable path is NOT set in PATH!"
		echo "$MOBILE_GENERATOR_LINE_PREFIX : Please install the same and/or set the PATH variable and retry running this script."
		return_code=$EXIT_ADB_VERSION_COMMAND_ERROR_CODE
		return
	fi
	echo "$MOBILE_GENERATOR_LINE_PREFIX : adb executable is found to be in the PATH. Continuing ahead..."
	
	# emulator command check
	android_emulator_command_check=$(emulator -help 2>&1)
	if [ $? -gt 0 ]; then
		echo "$MOBILE_GENERATOR_LINE_PREFIX : Emulator command executable path is not found. Either Android SDK tools not installed or emulator executable path is NOT set in PATH!"
		echo "$MOBILE_GENERATOR_LINE_PREFIX : Please install the same and^/or set the PATH variable and retry running this script."
		return_code=$EXIT_EMULATOR_HELP_COMMAND_ERROR_CODE
		return

	fi
	echo "$MOBILE_GENERATOR_LINE_PREFIX : emulator executable is found to be in the PATH. Continuing ahead..."
	
	# at least one AVD should be configured
	android_emulator_avds=$(emulator -list-avds 2>&1)
	if [ $? -gt 0 ]; then
		echo "$MOBILE_GENERATOR_LINE_PREFIX : Error getting the configured AVDs!"
		echo "$MOBILE_GENERATOR_LINE_PREFIX : The error details are:"
		echo "$android_emulator_avds"
		echo "$MOBILE_GENERATOR_LINE_PREFIX : Please fix emulator command execution errors displayed above and retry running this script."
		return_code=$EXIT_EMULATOR_LIST_AVDS_COMMAND_ERROR_CODE
		return

	fi
	avds=$(emulator -list-avds | wc -l 2>&1)
	if [[ $avds -lt 1 ]]; then
		echo "$MOBILE_GENERATOR_LINE_PREFIX : Not a single Android Virtual Device - AVD - or Emulator image is set up!"
		echo "$MOBILE_GENERATOR_LINE_PREFIX : Please set up at least one AVD and retry running this script."
		return_code=$EXIT_EMULATOR_HELP_COMMAND_ERROR_CODE
		return
	fi
	echo "$MOBILE_GENERATOR_LINE_PREFIX : Found $avds AVDs configured for the emulator."
	echo "$MOBILE_GENERATOR_LINE_PREFIX : Pre-requisites validation completed successfully."
}

# function cert issuer prompt - AppBrahma root CA signed server cert or 3rd party signed server cert?
cert_issuer_selection_prompt() {
	return_code=0
	echo "$MOBILE_GENERATOR_LINE_PREFIX : For https support by Android App, a signed server certificate needs to be deployed onto the Android emulator/device"
	echo "system store. Appbrahma MVP generator has already created AppBrahma root CA signed server certificate which will be deployed now onto"
	echo "Android emulator/device system store. This deployment step is needed to enable Unimobile app communicate with the back-end server using HTTPS for "
	echo "testing the app."
	echo ""
	echo "$MOBILE_GENERATOR_LINE_PREFIX : For this or any third party root CA signed server certificate deployment where the root CA certificate is not "
	echo "deployed in the Android system store by default, AVD must not run a production build to enable so-signed root CA certificate deployment to the "
	echo "emulator device."
	echo ""
	echo "$MOBILE_GENERATOR_LINE_PREFIX : This certificate deployment step is NOT needed if you use server signed certificate issued by a root CA"
	echo "whose root certificate is already deployed onto the Android system store you are targeting to test or if you are using  HTTP protocol."
	echo ""
	
	echo "$MOBILE_GENERATOR_LINE_PREFIX : Next step:"	
	PS3='Please select your choice by typing the number shown above for next step... '
	select uChoice in "Continue with AppBrahma root CA signed server certificate deployment to emulator/device" "Continue with a third party signed server certificate which is already deployed to device/emulator system store"
	do
		echo ""
		echo "$MOBILE_GENERATOR_LINE_PREFIX : You have selected the option - \"$REPLY) $uChoice\""
		echo ""
		if [[ "$uChoice" != ""  ]]; then
			break
		fi
	done
	if [ $REPLY -eq 2 ]; then
		echo "$MOBILE_GENERATOR_LINE_PREFIX : Skipping the AppBrahma root CA server certificate deployment process..."		
		return_code=$THIRD_PARTY_CERT_DEPLOYED
		return
	else
		if [ $REPLY -ne 1 ]; then
			echo "$MOBILE_GENERATOR_LINE_PREFIX : You have typed an invalid value - $REPLY - for the selection!"
			echo "$MOBILE_GENERATOR_LINE_PREFIX : Valid values are 1 or 2. Aborting the execution."
			echo "$MOBILE_GENERATOR_LINE_PREFIX : Please retry with valid values for the selection."
			return_code=$INVALID_CERT_ISSUER_SELECTION	
			return
		fi	
	fi
	return_code=$APPBRAHMA_CERT_DEPLOYMENT
	return
}

# function cert deployment pre-reqs check
unimo_cert_deployment_pre_reqs_validation() {	
	return_code=0
	echo "$MOBILE_GENERATOR_LINE_PREFIX : Checking for openSSL..."
	openssl_command_check=$(openssl version 2>&1)
	if [ $? -gt 0 ]; then
		echo "$MOBILE_GENERATOR_LINE_PREFIX : OpenSSL application is needed to deploy the certificate but the executable is not found in the PATH!"
		echo "$MOBILE_GENERATOR_LINE_PREFIX : Please install/fix the PATH for openSSL and retry running this script."
		return_code=$EXIT_OPENSSL_NOT_IN_PATH_ERROR_CODE
		return
	fi
	echo "$MOBILE_GENERATOR_LINE_PREFIX : openSSL needed for certificate deployment onto emulator is found in the PATH. Continuing ahead..."
	return 0
}

# function for https prep-up
https_prep_up() {
	return_code=0
	echo ""
	echo "$MOBILE_GENERATOR_LINE_PREFIX : Unimobile app will be built and run for communicating with back-end server using HTTPS protocol."
	echo ""
	echo "$MOBILE_GENERATOR_LINE_PREFIX : Please modify and ensure the web protocol in "apiUrl" key value to "https" in src/environments/environment.ts of"
	echo "Unimobile sources project directory and save the file to proceed further."
	echo ""
	echo "	Example 1 - apiUrl: 'https://192.168.0.114:8091/api'"
	echo "	Example 2 - apiUrl: 'https://localhost:8091/api'"
	echo ""
	read -p "$MOBILE_GENERATOR_LINE_PREFIX :  Press any key to continue after modification and saving the file... "	
	echo ""
	cert_issuer_selection_prompt
	if [[ $return_code -eq $INVALID_CERT_ISSUER_SELECTION ]]; then
		echo "$MOBILE_GENERATOR_LINE_PREFIX : Invalid selection for next step!"
		echo "$MOBILE_GENERATOR_LINE_PREFIX : Please re-run this script and make a valid selection."
		return_code=$INVALID_CERT_ISSUER_SELECTION
		return
	else
		if [[ $return_code -eq $THIRD_PARTY_CERT_DEPLOYED ]]; then
			echo "$MOBILE_GENERATOR_LINE_PREFIX : Continuing ahead to the next step..."
			return_code=$THIRD_PARTY_CERT_DEPLOYED
			return
		fi
	fi
	echo "$MOBILE_GENERATOR_LINE_PREFIX : Validating pre-requisites for server certificate deployment..."
	unimo_cert_deployment_pre_reqs_validation
	if [[ $return_code -ne 0 ]]; then
		echo "$MOBILE_GENERATOR_LINE_PREFIX : HTTPS certificate deployment pre-requisites validation failed!"
		echo "$MOBILE_GENERATOR_LINE_PREFIX : Aborting the execution."
		echo "$MOBILE_GENERATOR_LINE_PREFIX : Please retry running this script after fixing the reported errors."
		return_code=$EXIT_CERT_DEPLOYMENT_PRE_REQ_CHECK_FAILURE_CODE
		return
	fi
	echo "$MOBILE_GENERATOR_LINE_PREFIX : Pre-requisites for server certificate deployment are fulfilled. Continuing ahead."
	return
}

# function making a copy of the signed cert with hashname
signed_ca_cert_rename_for_android() {
	return_code=0
	echo "$CERT_DEPLOYER_LINE_PREFIX : Preparing the certificate for deploying..."
	cert_hash_value_command_result=$(openssl x509 -inform PEM -subject_hash_old -in appbrahma-root-ca-signed-server.crt | awk 'NR==1')
	if [[ $? -ne 0 ]]; then
		echo "$CERT_DEPLOYER_LINE_PREFIX : Error generating hash code of the certificate needed to deploy!"
		echo "$CERT_DEPLOYER_LINE_PREFIX : The error details are displayed below:"
		echo $cert_hash_value_command_result
		echo "$CERT_DEPLOYER_LINE_PREFIX : Please fix above errors and retry running this script."
		return_code=$EXIT_CERT_HASH_GEN_COMMAND_ERROR_CODE
		return 
	fi
	if [[ "$cert_hash_value_command_result" == "" ]]; then 
		echo "$CERT_DEPLOYER_LINE_PREFIX : Error generating hash code of the certificate needed to deploy!"
		echo "$CERT_DEPLOYER_LINE_PREFIX : The hash code generated is empty! Please retry running this script."		
		return_code=$EXIT_CERT_HASH_GEN_COMMAND_ERROR_CODE
		return 
	fi
	echo "$CERT_DEPLOYER_LINE_PREFIX : Generated hashcode is $cert_hash_value_command_result."	
	
	create_cert_with_hash_value_name=$(cp -f $signed_cert_name $cert_hash_value_command_result.0 2>&1)
	if [[ $? -ne 0 ]]; then 
		echo "$CERT_DEPLOYER_LINE_PREFIX : Error preparing the certificate for the deployment!"
		echo "$CERT_DEPLOYER_LINE_PREFIX : The error is:"
		echo $create_cert_with_hash_value_name
		echo "$CERT_DEPLOYER_LINE_PREFIX : Please fix above errors and retry running this script."
		return_code=$EXIT_CERT_HASH_GEN_COMMAND_ERROR_CODE
		return
	fi
	echo "$CERT_DEPLOYER_LINE_PREFIX : Prepared the server Appbrahma root CA signed server certificate for android device deployment."
	return_code=0
}

# function cert deployment to devices above sdk_api_level 28
cert_deployment_to_devices_gt_sdk_api_level_28() {
	return_code=0
	signed_ca_cert_rename_for_android
	if [[ $return_code -ne 0 ]]; then
		return
	fi
	echo "$CERT_DEPLOYER_LINE_PREFIX : Signed server certificate is prepared with hashcode name to be copied into Android system store and beginning the deployment..."
	
	echo "$CERT_DEPLOYER_LINE_PREFIX : Restarting adb as root..."
	adb_root=$(adb root 2>&1)
	if [[ $? -ne 0 ]]; then
		if [[  ! "$adb_root" =~ "already running as root" ]]; then
			echo "$CERT_DEPLOYER_LINE_PREFIX : Error restarting the adb as root!"
			echo "$CERT_DEPLOYER_LINE_PREFIX : The error is:"
			echo $adb_root
			echo "$CERT_DEPLOYER_LINE_PREFIX : Please ensure that you have waited until the emulator home screen was displayed and that the emulator was running in your retry."
			return_code=$EXIT_RESTART_ADB_AS_ROOT_COMMAND_ERROR_CODE
			return		
		fi
	fi
	echo "$CERT_DEPLOYER_LINE_PREFIX : Now disabling emulator secure boot verification for deploying the signed certificate to android system store..."
	disable_secure_boot_command_res=$(adb shell avbctl disable-verification 2>&1)
	if [[ $? -ne 0 ]]; then
		echo "$CERT_DEPLOYER_LINE_PREFIX : Error disabling secure boot verification for deployment!"
		echo "$CERT_DEPLOYER_LINE_PREFIX : The error is:"
		echo $disable_secure_boot_command_res
		echo "$CERT_DEPLOYER_LINE_PREFIX : Please retry running ths script.."
		return_code=$EXIT_DISABLE_SECURE_ROOT_COMMAND_ERROR_CODE
		return
	fi
	echo "$CERT_DEPLOYER_LINE_PREFIX : Disabled emulator secure boot verification."
	
	echo "$CERT_DEPLOYER_LINE_PREFIX : Now rebooting adb..."
	adb_reboot_command_res=$(adb reboot 2>&1)
	if [[ $? -ne 0 ]]; then 
		echo "$CERT_DEPLOYER_LINE_PREFIX : Error rebooting!"
		echo "$CERT_DEPLOYER_LINE_PREFIX : The error is:"
		echo $adb_reboot_command_res
		echo "$CERT_DEPLOYER_LINE_PREFIX : Please retry running ths script."
		return_code=$EXIT_ADB_REBOOT_COMMAND_ERROR_CODE
		return
	fi
	echo ""
	echo "$CERT_DEPLOYER_LINE_PREFIX : Wait for the emulator to complete the reboot - until you see current screen disappear and home screen pop up."
	echo ""
	read -p "$CERT_DEPLOYER_LINE_PREFIX : Press any key to continue, when ready... "	
	
	echo "$CERT_DEPLOYER_LINE_PREFIX : Restarting adb as root..."
	adb_root_command_res=$(adb root 2>&1)
	if [[ $? -ne 0 ]]; then 
		echo "$CERT_DEPLOYER_LINE_PREFIX : Error restarting the adb as root!"
		echo "$CERT_DEPLOYER_LINE_PREFIX : The error is:"
		echo $adb_root_command_res
		echo "$CERT_DEPLOYER_LINE_PREFIX : Please ensure that you have waited until the emulator home screen was displayed and that the emulator was running in your retry."
		return_code=$EXIT_RESTART_ADB_AS_ROOT_COMMAND_ERROR_CODE
		return
	fi
	echo "$CERT_DEPLOYER_LINE_PREFIX : Restarted adb as root."
	
	echo "$CERT_DEPLOYER_LINE_PREFIX : Remounting device partition for read-write..."
	adb_remount_command_res=$(adb remount 2>&1)
	if [[ $? -ne 0 ]]; then 
		echo "$CERT_DEPLOYER_LINE_PREFIX : Error remounting device partition for reading and writing!"
		echo "$CERT_DEPLOYER_LINE_PREFIX : The error is:"
		echo $adb_remount_command_res
		echo "$CERT_DEPLOYER_LINE_PREFIX : Please retry running ths script."
		return_code=$EXIT_REMOUNT_PARTITIONS_COMMAND_ERROR_CODE
		return
	fi
	echo "$CERT_DEPLOYER_LINE_PREFIX : Remounted device partition for read-write."
	
	echo "$CERT_DEPLOYER_LINE_PREFIX : Now rebooting adb..."
	adb_reboot_command_res=$(adb reboot 2>&1)
	if [[ $? -ne 0 ]]; then 
		echo "$CERT_DEPLOYER_LINE_PREFIX : Error rebooting!"
		echo "$CERT_DEPLOYER_LINE_PREFIX : The error is:"
		echo $adb_reboot_command_res
		echo "$CERT_DEPLOYER_LINE_PREFIX : Please retry running ths script."
		return_code=$EXIT_ADB_REBOOT_COMMAND_ERROR_CODE
		return
	fi
	echo ""
	echo "$CERT_DEPLOYER_LINE_PREFIX : Wait for the emulator to complete the reboot - until you see current screen disappear and home screen pop up."
	echo ""
	read -p "$CERT_DEPLOYER_LINE_PREFIX : Press any key to continue, when ready... "
	
	echo "$CERT_DEPLOYER_LINE_PREFIX : Restarting adb as root..."
	adb_root_command_res=$(adb root 2>&1)
	if [[ $? -ne 0 ]]; then 
		echo "$CERT_DEPLOYER_LINE_PREFIX : Error restarting the adb as root!"
		echo "$CERT_DEPLOYER_LINE_PREFIX : The error is:"
		echo $adb_root_command_res
		echo "$CERT_DEPLOYER_LINE_PREFIX : Please ensure that you have waited until the emulator home screen was displayed and that the emulator was running in your retry."
		return_code=$EXIT_RESTART_ADB_AS_ROOT_COMMAND_ERROR_CODE
		return
	fi
	echo "$CERT_DEPLOYER_LINE_PREFIX : Restarted adb as root."
	
	echo "$CERT_DEPLOYER_LINE_PREFIX : Mounting android device partition after reboot..."
	adb_remount_command_res=$(adb remount 2>&1)
	if [[ $? -ne 0 ]]; then 
		echo "$CERT_DEPLOYER_LINE_PREFIX : Error mounting android partition for reading and writing!"
		echo "$CERT_DEPLOYER_LINE_PREFIX : The error is:"
		echo $adb_remount_command_res
		echo "$CERT_DEPLOYER_LINE_PREFIX : Please retry running ths script."
		return_code=$EXIT_REMOUNT_PARTITIONS_COMMAND_ERROR_CODE
		return
	fi
	echo "$CERT_DEPLOYER_LINE_PREFIX : Mounted android device partition for read-write after reboot."
	
	echo "$CERT_DEPLOYER_LINE_PREFIX : Pushing AppBrahma root CA signed server certiciate into Android device system store..."
	echo "$CERT_DEPLOYER_LINE_PREFIX : Certificate is stored as $cert_hash_value_command_result.0 as per android system requirement"
	adb_cert_push_command_res=$(adb push $cert_hash_value_command_result.0 /system/etc/security/cacerts 2>&1)	
	if [[ $? -ne 0 ]]; then
		echo "$CERT_DEPLOYER_LINE_PREFIX : Error pushing the signed server certificate to android device system store!"
		echo "$CERT_DEPLOYER_LINE_PREFIX : The error is:"
		echo $adb_cert_push_command_res
		echo "$CERT_DEPLOYER_LINE_PREFIX : Please retry running ths script."
		return_code=$EXIT_PUSH_SIGNED_CERT_COMMAND_ERROR_CODE
		return
	fi
	echo "$CERT_DEPLOYER_LINE_PREFIX : The result of the certificate push as reported by ADB is:"
	echo $adb_cert_push_command_res
	echo "$CERT_DEPLOYER_LINE_PREFIX : Pushed AppBrahma root CA signed server certiciate to Android device system store."
	delete_file=$(rm -rf "$cert_hash_value_command_result.0" 2>&1)
	
	echo "$CERT_DEPLOYER_LINE_PREFIX : Setting the certificate permissions..."
	adb_shell_chmod_command_res=$(adb shell chmod 664 /system/etc/security/cacerts/$cert_hash_value_command_result.0 2>&1)
	if [[ $? -ne 0 ]]; then
		echo "$CERT_DEPLOYER_LINE_PREFIX : Error setting the permissions to the pushed server certificate in android device system store!"
		echo "$CERT_DEPLOYER_LINE_PREFIX : The error is:"
		echo $adb_shell_chmod_command_res
		echo "$CERT_DEPLOYER_LINE_PREFIX : Please retry running ths script."
		return_code= $EXIT_PUSH_SIGNED_CERT_COMMAND_ERROR_CODE
		return
	fi
	echo "$CERT_DEPLOYER_LINE_PREFIX : Certificate permissions set."
	
	echo "$CERT_DEPLOYER_LINE_PREFIX : Now rebooting adb..."
	adb_reboot_command_res=$(adb reboot 2>&1)
	if [[ $? -ne 0 ]]; then 
		echo "$CERT_DEPLOYER_LINE_PREFIX : Error rebooting!"
		echo "$CERT_DEPLOYER_LINE_PREFIX : The error is:"
		echo $adb_reboot_command_res
		echo "$CERT_DEPLOYER_LINE_PREFIX : Please retry running ths script."
		return_code=$EXIT_ADB_REBOOT_COMMAND_ERROR_CODE
		return
	fi
	echo ""
	echo "$CERT_DEPLOYER_LINE_PREFIX : Wait for the emulator to complete the reboot - until you see current screen disappear and home screen pop up."
	echo ""
	read -p "$CERT_DEPLOYER_LINE_PREFIX : Press any key to continue, when ready... "
	
	echo "$CERT_DEPLOYER_LINE_PREFIX : AppBrahma root CA signed server certificate is successfully deployed to Android emulator for testing Unimobile App with back-end AppBrahma web server."
	echo ""
	echo "$CERT_DEPLOYER_LINE_PREFIX : Please be aware that if you close this emulator and re-open from outside this script for testing Unimobile app using HTTPS - it won't work due to the restrictions imposed by Android API level security. Only way to test HTTPS communication with server for AppBrahma root CA signed server certificate or any other self-signed certificates is to go through this script and let the emulator run for the full testing session."
	echo ""
	return
}

# function cert deployment to devices of  sdk_api_level 28 or below
cert_deployment_to_devices_leq_sdk_api_level_28() {
	return_code=0
	signed_ca_cert_rename_for_android
	if [[ $return_code -ne 0 ]]; then
		return
	fi
	echo "$CERT_DEPLOYER_LINE_PREFIX : Signed server certificate is prepared with hashcode name to be copied into Android system store and beginning the deployment..."
	
	echo "$CERT_DEPLOYER_LINE_PREFIX : Restarting adb as root..."
	adb_root=$(adb root 2>&1)
	if [[ $? -ne 0 ]]; then
		if [[  ! "$adb_root" =~ "already running as root" ]]; then
			echo "$CERT_DEPLOYER_LINE_PREFIX : Error restarting the adb as root!"
			echo "$CERT_DEPLOYER_LINE_PREFIX : The error is:"
			echo $adb_root
			echo "$CERT_DEPLOYER_LINE_PREFIX : Please ensure that you have waited until the emulator home screen was displayed and that the emulator was running in your retry."
			return_code=$EXIT_RESTART_ADB_AS_ROOT_COMMAND_ERROR_CODE
			return		
		fi
	fi
		
	echo "$CERT_DEPLOYER_LINE_PREFIX : Remounting device partition for read-write..."
	adb_remount_command_res=$(adb remount 2>&1)
	if [[ $? -ne 0 ]]; then 
		echo "$CERT_DEPLOYER_LINE_PREFIX : Error remounting device partition for reading and writing!"
		echo "$CERT_DEPLOYER_LINE_PREFIX : The error is:"
		echo $adb_remount_command_res
		echo "$CERT_DEPLOYER_LINE_PREFIX : Please retry running ths script."
		return_code=$EXIT_REMOUNT_PARTITIONS_COMMAND_ERROR_CODE
		return
	fi
	echo "$CERT_DEPLOYER_LINE_PREFIX : Remounted device partition for read-write."
	
	echo "$CERT_DEPLOYER_LINE_PREFIX : Now rebooting adb..."
	adb_reboot_command_res=$(adb reboot 2>&1)
	if [[ $? -ne 0 ]]; then 
		echo "$CERT_DEPLOYER_LINE_PREFIX : Error rebooting!"
		echo "$CERT_DEPLOYER_LINE_PREFIX : The error is:"
		echo $adb_reboot_command_res
		echo "$CERT_DEPLOYER_LINE_PREFIX : Please retry running ths script."
		return_code=$EXIT_ADB_REBOOT_COMMAND_ERROR_CODE
		return
	fi
	echo ""
	echo "$CERT_DEPLOYER_LINE_PREFIX : Wait for the emulator to complete the reboot - until you see current screen disappear and home screen pop up."
	echo ""
	read -p "$CERT_DEPLOYER_LINE_PREFIX : Press any key to continue, when ready... "
	
	echo "$CERT_DEPLOYER_LINE_PREFIX : Restarting adb as root..."
	adb_root_command_res=$(adb root 2>&1)
	if [[ $? -ne 0 ]]; then 
		echo "$CERT_DEPLOYER_LINE_PREFIX : Error restarting the adb as root!"
		echo "$CERT_DEPLOYER_LINE_PREFIX : The error is:"
		echo $adb_root_command_res
		echo "$CERT_DEPLOYER_LINE_PREFIX : Please ensure that you have waited until the emulator home screen was displayed and that the emulator was running in your retry."
		return_code=$EXIT_RESTART_ADB_AS_ROOT_COMMAND_ERROR_CODE
		return
	fi
	echo "$CERT_DEPLOYER_LINE_PREFIX : Restarted adb as root."
	
	echo "$CERT_DEPLOYER_LINE_PREFIX : Mounting android device partition after reboot..."
	adb_remount_command_res=$(adb remount 2>&1)
	if [[ $? -ne 0 ]]; then 
		echo "$CERT_DEPLOYER_LINE_PREFIX : Error mounting android partition for reading and writing!"
		echo "$CERT_DEPLOYER_LINE_PREFIX : The error is:"
		echo $adb_remount_command_res
		echo "$CERT_DEPLOYER_LINE_PREFIX : Please retry running ths script."
		return_code=$EXIT_REMOUNT_PARTITIONS_COMMAND_ERROR_CODE
		return
	fi
	echo "$CERT_DEPLOYER_LINE_PREFIX : Mounted android device partition for read-write after reboot."
	
	echo "$CERT_DEPLOYER_LINE_PREFIX : Pushing AppBrahma root CA signed server certiciate into Android device system store..."
	echo "$CERT_DEPLOYER_LINE_PREFIX : Certificate is stored as $cert_hash_value_command_result.0 as per android system requirement"
	adb_cert_push_command_res=$(adb push $cert_hash_value_command_result.0 /system/etc/security/cacerts 2>&1)	
	if [[ $? -ne 0 ]]; then
		echo "$CERT_DEPLOYER_LINE_PREFIX : Error pushing the signed server certificate to android device system store!"
		echo "$CERT_DEPLOYER_LINE_PREFIX : The error is:"
		echo $adb_cert_push_command_res
		echo "$CERT_DEPLOYER_LINE_PREFIX : Please retry running ths script."
		return_code=$EXIT_PUSH_SIGNED_CERT_COMMAND_ERROR_CODE
		return
	fi
	echo "$CERT_DEPLOYER_LINE_PREFIX : The result of the certificate push as reported by ADB are:"
	echo $adb_cert_push_command_res
	echo "$CERT_DEPLOYER_LINE_PREFIX : Pushed AppBrahma root CA signed server certiciate to Android device system store."
	delete_file=$(rm -rf "$cert_hash_value_command_result.0" 2>&1)
	
	echo "$CERT_DEPLOYER_LINE_PREFIX : Setting the certificate permissions..."
	adb_shell_chmod_command_res=$(adb shell chmod 664 /system/etc/security/cacerts/$cert_hash_value_command_result.0 2>&1)
	if [[ $? -ne 0 ]]; then
		echo "$CERT_DEPLOYER_LINE_PREFIX : Error setting the permissions to the pushed server certificate in android device system store!"
		echo "$CERT_DEPLOYER_LINE_PREFIX : The error is:"
		echo $adb_shell_chmod_command_res
		echo "$CERT_DEPLOYER_LINE_PREFIX : Please retry running ths script."
		return_code= $EXIT_PUSH_SIGNED_CERT_COMMAND_ERROR_CODE
		return
	fi
	echo "$CERT_DEPLOYER_LINE_PREFIX : Certificate permissions set."
	
	echo "$CERT_DEPLOYER_LINE_PREFIX : Now rebooting adb..."
	adb_reboot_command_res=$(adb reboot 2>&1)
	if [[ $? -ne 0 ]]; then 
		echo "$CERT_DEPLOYER_LINE_PREFIX : Error rebooting!"
		echo "$CERT_DEPLOYER_LINE_PREFIX : The error is:"
		echo $adb_reboot_command_res
		echo "$CERT_DEPLOYER_LINE_PREFIX : Please retry running ths script."
		return_code=$EXIT_ADB_REBOOT_COMMAND_ERROR_CODE
		return
	fi
	echo ""
	echo "$CERT_DEPLOYER_LINE_PREFIX : Wait for the emulator to complete the reboot - until you see current screen disappear and home screen pop up."
	echo ""
	read -p "$CERT_DEPLOYER_LINE_PREFIX : Press any key to continue, when ready... "
	
	echo "$CERT_DEPLOYER_LINE_PREFIX : AppBrahma root CA signed server certificate is successfully deployed to Android emulator for testing Unimobile App with back-end AppBrahma web server."
	echo ""
	echo "$CERT_DEPLOYER_LINE_PREFIX : Please be aware that if you close this emulator and re-open from outside this script for testing Unimobile app using HTTPS - it won't work due to the restrictions imposed by Android API level security. Only way to test HTTPS communication with server for AppBrahma root CA signed server certificate or any other self-signed certificates is to go through this script and let the emulator run for the full testing session."
	echo ""
	return
}

#function deploy certificate to avd
unimo_deploy_server_cert_to_device() {
	return_code=0
	# emulator select menu
	echo ""
	echo "$MOBILE_GENERATOR_LINE_PREFIX : Which device would you like to target?"	
	PS3='Please type the AVD number shown above for the target selection: '
	devices=$(emulator -list-avds)
	select target in $devices;
	do
		echo ""
		echo "$MOBILE_GENERATOR_LINE_PREFIX : You have chosen \"$REPLY) $target\" as the target "	
		if [[ "$target" != "" ]]; then
			break
		fi	
	done
	echo "$CERT_DEPLOYER_LINE_PREFIX : If the emulator is already running this AVD, please close the running AVD and emulator."
	echo "$CERT_DEPLOYER_LINE_PREFIX : Additionally, if this AVD was created from the system image that is labelled or target as \"Google Play\" which runs a production build image, certificate cannot be deployed."
	echo "$CERT_DEPLOYER_LINE_PREFIX : If you try to run this script or deploy on the production build image, then this script would crash during the execution."
	echo ""
	read -p "$MOBILE_GENERATOR_LINE_PREFIX : Press any key to continue, when ready... "	
	echo ""
	signed_cert_name="appbrahma-root-ca-signed-server.crt"
	# cert file check
	if [ ! -f "$signed_cert_name" ]; then
		echo "$CERT_DEPLOYER_LINE_PREFIX : AppBrahma root CA signed server certificate is not found in the Unimobile source code project directory!"
		echo "$CERT_DEPLOYER_LINE_PREFIX : Aborting the execution."
		echo "$CERT_DEPLOYER_LINE_PREFIX : Please regenerate the application sources using AppBrahma platform and run this script from the newly generated Unimobile app project directory."
		return_code=$EXIT_CERT_HASH_GEN_COMMAND_ERROR_CODE
		return
	fi
	# run selected emu
	echo "$CERT_DEPLOYER_LINE_PREFIX : Starting $target to for the deployment preparation..."
	run_emulator=$(emulator -avd $target -writable-system 2>&1) &	
	if [[ $? -ne 0 ]]; then
		echo "$CERT_DEPLOYER_LINE_PREFIX : Error running $target!"
		echo "$CERT_DEPLOYER_LINE_PREFIX : The error details are displayed in the spawned windows."
		echo "$CERT_DEPLOYER_LINE_PREFIX : Please fix above errors and retry running this script."
		return_code=$EXIT_RUN_EMULATOR_COMMAND_ERROR_CODE
		return
	else		
		enable_no_case_match=$(shopt -s nocasematch 2>&1)
		if [[ "$run_emulator" =~ .*"PANIC: Missing emulator".* ]]; then
			enable_no_case_match=$(shopt -u nocasematch 2>&1)
			echo "$CERT_DEPLOYER_LINE_PREFIX : Error running $target!"
			echo "$CERT_DEPLOYER_LINE_PREFIX : The error details are below:"
			echo "$run_emulator"			
			echo "$CERT_DEPLOYER_LINE_PREFIX : Please fix above errors and retry running this script."
			return_code=$EXIT_RUN_EMULATOR_COMMAND_ERROR_CODE
			return
		fi
	fi
	echo ""
	echo "$CERT_DEPLOYER_LINE_PREFIX : The selected emulator is spawned as an independent process. If you do not see emulator starting up or see errors, re-run"
	echo "this script and select another emulator."
	echo "$CERT_DEPLOYER_LINE_PREFIX : Wait for the emulator to boot up completely - until you see device home screen and then press any key to continue..."
	echo ""
	read -p "$CERT_DEPLOYER_LINE_PREFIX : Press any key to continue, when ready... "	
	echo ""
	
	# adb connection check
	adb_conn_check=$(adb root 2>&1)
	if [[ $? -ne 0 ]]; then
		echo "$CERT_DEPLOYER_LINE_PREFIX : Unable to connect to $target!"
		echo "$CERT_DEPLOYER_LINE_PREFIX : The error is:"
		echo "$adb_conn_check"
		echo "$CERT_DEPLOYER_LINE_PREFIX : Please ensure that you have waited until the emulator home screen was displayed and that the emulator was running in your retry."
		return_code=$EXIT_RESTART_ADB_AS_ROOT_COMMAND_ERROR_CODE
		return
	else
		# if the image is production image, return code is still 0 but error message is displayed on STDOUT
		if [[ $adb_conn_check =~ "cannot run as root in production builds" ]]; then
			echo "$CERT_DEPLOYER_LINE_PREFIX : The AVD you are running is a production image!"
			echo "$CERT_DEPLOYER_LINE_PREFIX : Certificate cannot be deployed."
			echo "$CERT_DEPLOYER_LINE_PREFIX : Please retry with an AVD which is NOT a production image - that does not have Google Play as Target while creating it."
			return_code=$EXIT_RESTART_ADB_AS_ROOT_COMMAND_ERROR_CODE
			return
		fi		
	fi
	# android sdk api level
	echo "$CERT_DEPLOYER_LINE_PREFIX : Finding device android sdk API level..."
	device_sdk_api_level=$(adb shell getprop ro.build.version.sdk 2>&1)
	if [[ $? -gt 0 ]]; then
		echo "$CERT_DEPLOYER_LINE_PREFIX : Unable to get the connected device SDK API level. This is crucial for certificate deployment!"
		echo "$CERT_DEPLOYER_LINE_PREFIX : Please ensure the device/emulator is connected and developer settings are enabled as per the android version and retry running this script."
		echo "$CERT_DEPLOYER_LINE_PREFIX : The error details are:"
		echo "$device_sdk_api_level"
		echo "$CERT_DEPLOYER_LINE_PREFIX : Please fix above errors and retry running this script."
		return_code=$EXIT_GET_SDK_API_LEVEL_ERROR_CODE
		return
	fi
	echo "$CERT_DEPLOYER_LINE_PREFIX : Found device android SDK API level - $device_sdk_api_level"
	if [[ $device_sdk_api_level -gt 28 ]]; then
		cert_deployment_to_devices_gt_sdk_api_level_28
		if [[ $return_code -ne 0 ]]; then
			return
		fi
		
	else
		cert_deployment_to_devices_leq_sdk_api_level_28
		if [[ $return_code -ne 0 ]]; then
			return
		fi
	fi
	return 0
}

# function to re-install node deps
npm_reinstall() {
	return_code=0
	echo "$MOBILE_GENERATOR_LINE_PREFIX : Now re-installing nodejs dependencies..."
	NPM_INSTALL_DEPS_COMMAND_RES=$(npm install --force 2>&1)
	if [[ $? -ne 0 ]]; then
		echo "$MOBILE_GENERATOR_LINE_PREFIX : Re-attempt to install nodejs dependencies resulted in error!"
		echo "$MOBILE_GENERATOR_LINE_PREFIX : Error details are displayed below. Aborting Unimobile build and run process."
		echo "$MOBILE_GENERATOR_LINE_PREFIX : Please retry running this script after fixing these issues."
		echo $NPM_INSTALL_DEPS_COMMAND_RES
		return_code=$EXIT_NPM_INSTALL_COMMAND_ERROR_CODE
		return
	else	
		return_code=0
	fi
}

# function to install node dependencies
npm_install() {
	return_code=0
	NPM_INSTALL_DEPS_COMMAND_RES=$(npm install --force 2>&1)
	if [[ $? -ne 0 ]]; then		
		echo "$MOBILE_GENERATOR_LINE_PREFIX : Error installing node dependencies!"
		echo "$MOBILE_GENERATOR_LINE_PREFIX : Fixing the errors..."		
		delete_node_modules=$(rm -rf node_modules 2>&1)       
		if [[ $? -ne 0 ]]; then
			echo "$MOBILE_GENERATOR_LINE_PREFIX : Error removing node_modules for fixing dependencies install errors!"            
			echo "$MOBILE_GENERATOR_LINE_PREFIX : Error details are displayed below. Aborting the execution."
			echo $delete_node_modules
			echo "$MOBILE_GENERATOR_LINE_PREFIX : Please retry running the script after fixing these reported errors."
			return_code=$EXIT_NPM_INSTALL_COMMAND_ERROR_CODE
			return
		else 
			npm_reinstall
			if [[ $? -ne 0 ]]; then
				return
			fi
		fi
	fi
}

# function to build the project
ionic_build() {
	return_code=0
	ionic_build_command_res=$(ionic build 2>&1)
	if [[ $? -ne 0 ]]; then
		echo "$MOBILE_GENERATOR_LINE_PREFIX : Error building project!"
		echo "$MOBILE_GENERATOR_LINE_PREFIX : Error details are displayed below. Aborting Unimobile build and run process."
		echo "$MOBILE_GENERATOR_LINE_PREFIX : Please retry running the script after fixing these reported errors."
		echo "$ionic_build_command_res"
		return_code=$EXIT_IONIC_BUILD_COMMAND_ERROR_CODE
		return
	fi    	
}

# function to add capacitor android platform
add_cap_platform() {
	return_code=0
	ADD_CAPACITOR_ANDROID_PLATFORM_COMMAND_RES=$(ionic cap add android 2>&1)
	if [[ $? -ne 0 ]]; then
		echo "$MOBILE_GENERATOR_LINE_PREFIX : It appears Android capacitor platform was already installed or installed nodejs dependencies are incomptabile!"
		echo "$MOBILE_GENERATOR_LINE_PREFIX : Diagnosing for exact root cause..."
		
		# check for any capacitor cli version in-compatibility error. If so, delete node_modules and run a fresh build using the same script
		CAP_CLI_ERROR='Error while getting Capacitor CLI version'
		# if the android platform was already installed, delete the dir and re-install
		PLATFORM_ALREADY_INSTALLED='android platform is already installed'
		case $ADD_CAPACITOR_ANDROID_PLATFORM_COMMAND_RES in 
		*"$CAP_CLI_ERROR"*)	    		
			echo "$MOBILE_GENERATOR_LINE_PREFIX : Ionic capacitor version incompatibility found. Re-installing compatible dependencies and installing Android capacitor platform..."
			remove_android_platform_and_node_deps_res=$(rm -rf android node_modules www 2>&1)
			if [[ $? -ne 0 ]]; then
				echo "$MOBILE_GENERATOR_LINE_PREFIX : Error removing node_modules, android, and www directories for installig compatible dependencies for Android platform!"
				echo "$MOBILE_GENERATOR_LINE_PREFIX : Error details are displayed below. Aborting the execution."
				echo "$remove_android_platform_and_node_deps_res"
			    	return_code=$EXIT_IONIC_CAP_ADD_PLATFORM_COMMAND_ERROR_CODE
			    	return
		    	else
		    		return_code=$EXIT_IONIC_RE_RUN_INSTALL_AND_BUILD
		    		unimo_build_type=$build_type_redo_deps_build_cap_android_platform
		    		return
			fi			
		;;
		*"$PLATFORM_ALREADY_INSTALLED"*)
			echo "$MOBILE_GENERATOR_LINE_PREFIX : Android platform was already installed. For avoiding run-time errors, re-installing android platform..."
			remove_android_platform_command_res=$(rm -rf android 2>&1)
			if [[ $? -ne 0 ]]; then
				echo "$MOBILE_GENERATOR_LINE_PREFIX : Error removing android directory for re-installig Android platform!"
				echo "$MOBILE_GENERATOR_LINE_PREFIX : Error details are displayed below. Aborting the execution."
				echo $remove_android_platform_command_res
				echo "$MOBILE_GENERATOR_LINE_PREFIX : Please retry running the script after fixing these reported errors."
			    	return_code=$EXIT_IONIC_CAP_ADD_PLATFORM_COMMAND_ERROR_CODE
			    	return
			else			
				return_code=$EXIT_IONIC_REINSTALL_CAP_ANDROID_PLATFORM
			    	unimo_build_type=$build_type_android_platform_reinstall
				return
			fi
		;;
		esac
	fi
}

# function to build unimo app
unimo_install_ionic_deps_build_and_platform() {
	return_code=0
	if [[ $unimo_build_type -eq $build_type_all || $unimo_build_type -eq $build_type_redo_deps_build_cap_android_platform ]]; then
		echo "$MOBILE_GENERATOR_LINE_PREFIX : Now installing node dependencies..."
		npm_install
		if [[ $return_code -ne 0 ]]; then		
			echo "$MOBILE_GENERATOR_LINE_PREFIX : Error installing node dependencies!"
			echo "$MOBILE_GENERATOR_LINE_PREFIX : Error details are displayed above. Please fix these issues and re-run this script."
			return
		fi
		echo "$MOBILE_GENERATOR_LINE_PREFIX : Installed node dependencies."
		
		echo "$MOBILE_GENERATOR_LINE_PREFIX : Now building the project..."
		ionic_build
		if [[ $return_code -ne 0 ]]; then		
			echo "$MOBILE_GENERATOR_LINE_PREFIX : Error building the project!"
			echo "$MOBILE_GENERATOR_LINE_PREFIX : Error details are displayed above. Please fix these issues and re-run this script."
			return		
		fi
		echo "$MOBILE_GENERATOR_LINE_PREFIX : Project built successfully."		
	fi
	echo "$MOBILE_GENERATOR_LINE_PREFIX : Now installing capacitor Android platform..."
	add_cap_platform
	case $return_code in 
		$EXIT_IONIC_REINSTALL_CAP_ANDROID_PLATFORM)
			unimo_build_type=$build_type_android_platform_reinstall
			unimo_install_ionic_deps_build_and_platform
			if [[ $return_code -ne 0 ]]; then
				return
			fi
		;;
		$EXIT_IONIC_RE_RUN_INSTALL_AND_BUILD)
			unimo_build_type=$build_type_redo_deps_build_cap_android_platform
			unimo_install_ionic_deps_build_and_platform
			if [[ $return_code -ne 0 ]]; then
				return
			fi	
		;;
		0)
			echo "$MOBILE_GENERATOR_LINE_PREFIX : Installed capacitor Android platform."
			return_code=0
			return
		;;
		*)
			echo "$MOBILE_GENERATOR_LINE_PREFIX : Error installing android capacitor platform!"
			echo "$MOBILE_GENERATOR_LINE_PREFIX : Error details are displayed above. Please fix these issues and re-run this script."			
			return_code=$EXIT_IONIC_CAP_ADD_PLATFORM_COMMAND_ERROR_CODE
		;;
	esac
}

# main script
# agrs check
if [ "$#" -ne $expected_arg_count ]; then
	echo "$MOBILE_GENERATOR_LINE_PREFIX : Invalid arguments supplied to the script!"
	echo ""
	echo "Usage:"	
	echo "./apb-windows-build-n-run-android.sh <build_task_type> <server_protocol>"
	echo "	Example 1 : apb-windows-build-n-run-android.sh build http"
	echo "	Example 2 : apb-windows-build-n-run-android.sh build https"
	echo "	Example 3 : apb-windows-build-n-run-android.sh rebuild http"
	echo "	Example 4 : apb-windows-build-n-run-android.sh rebuild https"
	exit $EXIT_WRONG_PARAMS_ERROR_CODE
fi

# clear the screen for visibility
clear

echo "=========================================================================================================================================="
echo "			Welcome to $MOBILE_GENERATOR_NAME Unimobile app build and run script for development and testing - non-production"
echo "Sit back, relax, and sip a cuppa coffee while the dependencies are downloaded, project is built, and run."
echo "Unless the execution of this script stops, do not be bothered nor worried about any warnings or errors displayed during the execution ;-)"
echo "=========================================================================================================================================="
echo ""

# globbed return value used by functions
return_code=0

if [ "$build_rebuild" == "rebuild" ]; then
	echo "$MOBILE_GENERATOR_LINE_PREFIX : Rebuild is requested. Cleaning the project for the rebuild..."
	if [ -d "node_modules" ]; then		
		delete_dir=$(rm -rf "node_modules" 2>&1)
		if [ $? -gt 0 ]; then
			echo "$MOBILE_GENERATOR_LINE_PREFIX : Error removing node_modules directory for rebuilding!"
			echo "$MOBILE_GENERATOR_LINE_PREFIX : Error details are displayed below. Aborting the execution."
			echo "$delete_dir"
			echo "$MOBILE_GENERATOR_LINE_PREFIX : Please retry running the script after fixing these reported errors."
			exit $EXIT_PROJ_REBUILD_ERROR_CODE
		fi
	fi
	if [ -d "android" ]; then		
		delete_dir=$(rm -rf "android" 2>&1)
		if [ $? -gt 0 ]; then
			echo "$MOBILE_GENERATOR_LINE_PREFIX : Error removing node_modules directory for rebuilding!"
			echo "$MOBILE_GENERATOR_LINE_PREFIX : Error details are displayed below. Aborting the execution."
			echo "$delete_dir"
			echo "$MOBILE_GENERATOR_LINE_PREFIX : Please retry running the script after fixing these reported errors."
			exit $EXIT_PROJ_REBUILD_ERROR_CODE
		fi
	fi
	if [ -d "www" ]; then		
		delete_dir=$(rm -rf "www" 2>&1)
		if [ $? -gt 0 ]; then
			echo "$MOBILE_GENERATOR_LINE_PREFIX : Error removing node_modules directory for rebuilding!"
			echo "$MOBILE_GENERATOR_LINE_PREFIX : Error details are displayed below. Aborting the execution."
			echo "$delete_dir"
			echo "$MOBILE_GENERATOR_LINE_PREFIX : Please retry running the script after fixing these reported errors."
			exit $EXIT_PROJ_REBUILD_ERROR_CODE
		fi
	fi
fi

echo "$MOBILE_GENERATOR_LINE_PREFIX : Validating pre-requisites..."
unimo_common_pre_reqs_validation
if [[ $return_code -ne 0 ]]; then
	echo "$MOBILE_GENERATOR_LINE_PREFIX : Pre-requisites validation failed!"
	echo "$MOBILE_GENERATOR_LINE_PREFIX : Aborting the execution."
	echo "$MOBILE_GENERATOR_LINE_PREFIX : Please retry running this script after fixing the reported errors."
	exit $EXIT_PRE_REQ_CHECK_FAILURE_CODE
fi

# https check for prep-up
if [[ "$server_rest_api_mode" == "https" ]]; then	
	#echo "$MOBILE_GENERATOR_LINE_PREFIX : For https support by Android Apps, a signed server certificate needs to be deployed into the Android emulator/device system store."
	#echo "Appbrahma MVP generator has already created root CA signed server certificate which will be deployed now into Android emulator/device system store."
	#echo "For this root CA certificate, the AVD must not run a production build to enable using adb root for server self-signed signed root CA certificate deployment to the emulator device."
	#echo "This step is NOT needed if you use generated server signed certificate issued by a CA whose root certificate is already deployed on the Android system store you are targeting to test or if you are using HTTP protocol."
	#echo ""
	#read -p "$CERT_DEPLOYER_LINE_PREFIX : Press any key to continue, when ready... "	
	
	https_prep_up	
	if [[ $return_code -eq $INVALID_CERT_ISSUER_SELECTION ]]; then
		echo "$MOBILE_GENERATOR_LINE_PREFIX : Error in preparing for https certificate deployment"
		echo "$MOBILE_GENERATOR_LINE_PREFIX : Invalid selection made for certificate issuer. Aborting the execution."
		echo "$MOBILE_GENERATOR_LINE_PREFIX : Please retry running this script and select valid values for the options."
		exit $EXIT_PRE_REQ_CHECK_FAILURE_CODE
	fi
	if [[ $return_code -eq $THIRD_PARTY_CERT_DEPLOYED ]]; then	
		third_party_cert=1	
		echo "$MOBILE_GENERATOR_LINE_PREFIX : Continuing ahead for building and deploying Unimobile app..."
	else
		unimo_deploy_server_cert_to_device
		if [[ $return_code -ne 0 ]]; then
			echo "$MOBILE_GENERATOR_LINE_PREFIX : HTTPS certificate deployment failed! Aborting the execution." 
			echo "$MOBILE_GENERATOR_LINE_PREFIX : Please retry running this script after fixing the reported errors."
			exit $EXIT_CERT_DEPLOYMENT_FAILURE_CODE
		fi	
	fi	
else
	echo ""
	echo "$MOBILE_GENERATOR_LINE_PREFIX : Unimobile app will be built and run for communicating with back-end server using HTTP protocol."
	echo ""
	echo "$MOBILE_GENERATOR_LINE_PREFIX : Please modify and ensure the web protocol in "apiUrl" key value to "http" in src/environments/environment.ts of"
	echo "Unimobile sources project directory and save the file to proceed further."
	echo ""
	echo "	Example 1 - apiUrl: 'http://192.168.0.114:8091/api'"
	echo "	Example 2 - apiUrl: 'http://localhost:8091/api'"
	echo ""
	read -p "$MOBILE_GENERATOR_LINE_PREFIX :  Press any key to continue after modification and saving the file... "	
	echo ""
	
fi
unimo_install_ionic_deps_build_and_platform
if [[ $return_code -ne 0 ]]; then
	echo "$MOBILE_GENERATOR_LINE_PREFIX : Error in building the project and installing android platform!"
	echo "$MOBILE_GENERATOR_LINE_PREFIX : Error details are displayed above. Aborting the execution."
	echo "$MOBILE_GENERATOR_LINE_PREFIX : Please retry running this script after fixing the displayed errors."
	exit $return_code
fi

# cordova-res install check -global
cordova_res_global_install_check_res=$(npm list -g cordova-res 2>&1)
if [[ $? -ne 0 ]]; then
	echo "$MOBILE_GENERATOR_LINE_PREFIX : cordova-res node module is not installed. This is needed for Unimobile app icon and splash customization."
	echo "$MOBILE_GENERATOR_LINE_PREFIX : Installing cordova-res..."
	cordova_global_install_res=$(npm install -g cordova-res 2>&1)
	if [[ $? -ne 0 ]]; then  	
		echo "$MOBILE_GENERATOR_LINE_PREFIX : Error installing cordova-res node module!"
		echo "$MOBILE_GENERATOR_LINE_PREFIX : Error details are:"
		echo $cordova_global_install_res
		echo "$MOBILE_GENERATOR_LINE_PREFIX : Aborting the execution. Please retry running this script after fixing the reported issues."
		exit $EXIT_CORDOVA_RES_COMMAND_INSTALL_ERROR_CODE
	fi
fi

echo "$MOBILE_GENERATOR_LINE_PREFIX : Customizing Unimobile application icon and splash images..."
customize_app_icons_res=$(cordova-res android --skip-config --copy 2>&1)
if [[ $? -ne 0 ]]; then
	echo "$MOBILE_GENERATOR_LINE_PREFIX : Error customizing the application icon and splash images!"
	echo "$MOBILE_GENERATOR_LINE_PREFIX : Error details are:"
	echo $customize_app_icons_res
	echo "$MOBILE_GENERATOR_LINE_PREFIX : Aborting the execution. Please retry running this script after fixing the reported issues.   "
	exit $EXIT_CORDOVA_RES_ICON_CUSTOMIZE_ERROR_CODE
fi
echo "$MOBILE_GENERATOR_LINE_PREFIX : Customized Unimobile application icon and splash images."
if [[ "$server_rest_api_mode" == "https" && $third_party_cert != 1 ]]; then
	echo "$MOBILE_GENERATOR_LINE_PREFIX : Running the Unimobile app on $target with https support..."
else
	# emu select menu
	echo ""
	echo "$MOBILE_GENERATOR_LINE_PREFIX : Which device would you like to target?"	
	PS3='Please type the AVD number shown above for the target selection: '
	devices=$(emulator -list-avds)
	select target in $devices;
	do
		echo ""
		echo "$MOBILE_GENERATOR_LINE_PREFIX : You have chosen \"$REPLY) $target\" as the target "	
		if [[ "$target" != "" ]]; then
			break
		fi	
	done
	echo "$MOBILE_GENERATOR_LINE_PREFIX : Starting Android emulator for running the Unimobile app on $target..."
fi
ionic_cap_run_android_command_res=$(ionic cap run android --target $target 2>&1)
if [[ $? -ne 0 ]]; then
	echo "$MOBILE_GENERATOR_LINE_PREFIX : Error running Android emulator and running your Unimobile application!"
	echo "$MOBILE_GENERATOR_LINE_PREFIX : Error details are:"
	echo $ionic_cap_run_android_command_res
    	echo "$MOBILE_GENERATOR_LINE_PREFIX : Please retry running this script after deleting the node_modules, android, and www directories in this project folder, if they exist."
	exit $EXIT_IONIC_CAP_ANDROID_RUN_COMMAND_ERROR_CODE
fi

# configure emulator avd to access the server port on the network
echo "$MOBILE_GENERATOR_LINE_PREFIX : Configuring Android simulator to access the Appbrahma server port on the network..."
adb_reverse_tcp_command_res=$(adb reverse tcp:8091 tcp:8091  2>&1)
if [[ $? -ne 0 ]]; then
	echo "$MOBILE_GENERATOR_LINE_PREFIX : Error confuguring android emulator to access the server port on the network!"
	echo "$MOBILE_GENERATOR_LINE_PREFIX : Error details are:"
	echo $adb_reverse_tcp_command_res
    	echo "$MOBILE_GENERATOR_LINE_PREFIX : Please try executing the command - \"adb reverse tcp:8091 tcp:8091\" - for establishing seamless connection between server and this app for REST calls."
	exit $EXIT_ADB_REVERSE_TCP_COMMAND_ERROR_CODE
fi

# display credentials for log in - for server integrated template
echo "$MOBILE_GENERATOR_LINE_PREFIX : Please use the below login credentials to login to the appbrahma backend server from unimobile app after running the backend server in a seperate terminal/console along with the DB server as chosen in your application configuration for generation"
echo "	Username: brahma"
echo "	Password: brahma@appbrahma"
