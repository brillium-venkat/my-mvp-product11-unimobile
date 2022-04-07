#!/bin/sh
# ==========================================================================================================================
# appbrahma-build-and-run-ios.sh
# AppBrahma iOS Unimobile App building and running
# Created by Venkateswar Reddy Melachervu on 16-11-2021.
# Updates:
#      17-12-2021 - Added gracious error handling and recovery mechansim for already added ios platform
#      29-01-2022 - Updated for ionic checks
#      27-02-2022 - Updated for streamlining exit error codes and re-organizing build code into a function for handling 
#                   dependency version incompatibilities
#      07-03-2022 - Updated for function exit codes, format and app display prefix
#      08-03-2022 - Synchronized with windows batch ejs file
# =======================================================================================================================


# Required version values
MOBILE_GENERATOR_NAME=UniBrahma
MOBILE_GENERATOR_LINE_PREFIX=\[$MOBILE_GENERATOR_NAME]
OS_MAJOR_VERSION=10
OS_MINOR_VERSION=0
OS_PATCH_VERSION=1
XCODE_MAJOR_VERSION=12
XCODE_MINOR_VERSION=0
XCODE_PATCH_VERSION=1
NODE_MAJOR_VERSION=16
NPM_MAJOR_VERSION=6
XCODE_SELECT_MIN_VERSION=2300
COCOAPODS_MAJOR_VERSION=1
IONIC_CLI_MAJOR_VERSION=6
IONIC_CLI_MINOR_VERSION=16
EXIT_ERROR_CODE=200
EXIT_MACOS_VERSION_CHECK_COMMAND_ERROR_CODE=201
EXIT_XCODE_VERSION_CHECK_COMMAND_ERROR_CODE=202
EXIT_XCODE_SELECT_VERSION_CHECK_COMMAND_ERROR_CODE=203
EXIT_NODE_VERSION_CHECK_COMMAND_ERROR_CODE=204
EXIT_COCOAPADS_VERSION_CHECK_COMMAND_ERROR_CODE=205
EXIT_NPM_VERSION_CHECK_COMMAND_ERROR_CODE=206
EXIT_IONIC_CLI_VERSION_CHECK_COMMAND_ERROR_CODE=207
EXIT_JAVA_VERSION_CHECK_COMMAND_ERROR_CODE=208
EXIT_JDK_VERSION_CHECK_COMMAND_ERROR_CODE=209
EXIT_NPM_INSTALL_COMMAND_ERROR_CODE=210
EXIT_IONIC_BUILD_COMMAND_ERROR_CODE=211
EXIT_IONIC_CAP_ADD_PLATFORM_COMMAND_ERROR_CODE=212
EXIT_UNIMO_INSTALL_BUILD_ERROR_CODE=213
EXIT_CORDOVA_RES_COMMAND_INSTALL_ERROR_CODE=214
EXIT_CORDOVA_RES_COMMAND_ERROR_CODE=215
EXIT_ADB_DEV_LIST_COMMAND_ERROR_CODE=216
EXIT_IONIC_CAP_RUN_COMMAND_ERROR_CODE=217
EXIT_ADB_REVERSE_COMMAND_ERROR_CODE=218

# node dependencies install, ionic build, and add capacitor platform
unimo_install_ionic_deps_build_and_platform() {   
    echo "$MOBILE_GENERATOR_LINE_PREFIX : Installing nodejs dependencies..."
    NPM_INSTALL_DEPS=$(npm install --force 2>&1)
    if [ $? -gt 0 ]; then
        echo "$MOBILE_GENERATOR_LINE_PREFIX : Error installing node dependencies!"
        echo "$MOBILE_GENERATOR_LINE_PREFIX : Fixing the errors..."  
        delete_node_modules=$(rm -rf node_modules 2>&1)        
        if [ $? -gt 0 ]; then
            echo "$MOBILE_GENERATOR_LINE_PREFIX : Error deleting the node_modules directory for fixing node dependency install errors!"
            echo "$MOBILE_GENERATOR_LINE_PREFIX : Error message is : $delete_node_modules"
            echo "$MOBILE_GENERATOR_LINE_PREFIX : Aborting the build and run process. Please delete the node_modules directory manually and retry running this script."
            exit $EXIT_NPM_INSTALL_COMMAND_ERROR_CODE
        else 
            echo "$MOBILE_GENERATOR_LINE_PREFIX : Fixed errors."
        fi

        echo "$MOBILE_GENERATOR_LINE_PREFIX : Now re-installing nodejs dependencies..."         
        NPM_INSTALL_DEPS=$(npm install --force 2>&1)
        if [ $? -gt 0 ]; then
            echo "$MOBILE_GENERATOR_LINE_PREFIX : Re-attempt to install nodejs dependencies resulted in error!"
            echo "$MOBILE_GENERATOR_LINE_PREFIX : Error details reported by npm are shown below."            
            echo "----------------------------------------------------------------------------------------------------------------------------------------------------------------------"
            echo $NPM_INSTALL_DEPS
            echo "----------------------------------------------------------------------------------------------------------------------------------------------------------------------"
            echo "$MOBILE_GENERATOR_LINE_PREFIX : Please retry running $MOBILE_GENERATOR_NAME build and run script after manually deleting the node_modules directory in this project directory."
            exit $EXIT_NPM_INSTALL_COMMAND_ERROR_CODE
        fi        
    fi
    echo "$MOBILE_GENERATOR_LINE_PREFIX : Installed nodejs dependencies."

    echo "$MOBILE_GENERATOR_LINE_PREFIX : Now building the project using ionic build..."
    ionic_build=$(ionic build 2>&1)
    if [ $? -gt 0 ]; then
	    echo "$MOBILE_GENERATOR_LINE_PREFIX : Error building unimobile application project. Error details reported by ionic build are displayed below"
	    echo "$MOBILE_GENERATOR_LINE_PREFIX : Aborting $MOBILE_GENERATOR_NAME unimobile build and run script." 
	    echo "$MOBILE_GENERATOR_LINE_PREFIX : Please retry running the script after fixing these reported errors."
	    echo "----------------------------------------------------------------------------------------------------------------------------------------------------------------------"
	    echo "$ionic_build"
	    echo "----------------------------------------------------------------------------------------------------------------------------------------------------------------------"
	    exit $EXIT_IONIC_BUILD_COMMAND_ERROR_CODE
    fi
    echo "$MOBILE_GENERATOR_LINE_PREFIX : Ionic build completed successfully."

    echo "$MOBILE_GENERATOR_LINE_PREFIX : Installing capacitor iOS platform..."
    ADD_CAPACITOR_IOS_PLATFORM=$(ionic cap add ios 2>&1)
    # $? is the result of last command executed - 0 in case of success and greater than 0 in case of error
    # $ADD_CAPACITOR_IOS_PLATFORM will hold the command execution output inclusive of error
    if [ $? -gt 0 ]; then
        # check if any capacitor cli version error. If so, delete node_modules and run a fresh build using the same script
        CAP_CLI_ERROR='Error while getting Capacitor CLI version'
        PLATFORM_ALREADY_INSTALLED='ios platform is already installed'

        case $ADD_CAPACITOR_IOS_PLATFORM in
            *"$CAP_CLI_ERROR"*)
                echo "$MOBILE_GENERATOR_LINE_PREFIX : Ionic capacitor version incompatibility found. Cleansing older dependencies, installing compatible dependencies for capacitor..."
                remove_ios_platform_and_node_deps=$(rm -rf ios node_modules www 2>&1)
                if [ $? -gt 0 ]; then
			echo "$MOBILE_GENERATOR_LINE_PREFIX : Error adding iOS platform - unable delete previously installed iOS platform! The error details are displayed below."
		    	echo "$MOBILE_GENERATOR_LINE_PREFIX : Aborting $MOBILE_GENERATOR_NAME unimobile build and run script."
		    	echo "$MOBILE_GENERATOR_LINE_PREFIX : Please retry running this script after fixing these errors."
		    	echo "----------------------------------------------------------------------------------------------------------------------------------------------------------------"
			echo "$remove_ios_platform_and_node_deps"
			echo "----------------------------------------------------------------------------------------------------------------------------------------------------------------"
		    	exit $EXIT_IONIC_CAP_ADD_PLATFORM_COMMAND_ERROR_CODE
		fi 
		unimo_install_ionic_deps_build_and_platform
		if [ $? -gt 0 ]; then
		    echo "$MOBILE_GENERATOR_LINE_PREFIX : Error adding iOS platform!"
		    echo "$MOBILE_GENERATOR_LINE_PREFIX : Aborting $MOBILE_GENERATOR_NAME unimobile build and run script."
		    echo "$MOBILE_GENERATOR_LINE_PREFIX : Please retry running this script after fixing above errors."
		    exit $EXIT_IONIC_CAP_ADD_PLATFORM_COMMAND_ERROR_CODE
		fi
            ;;
                
            *"$PLATFORM_ALREADY_INSTALLED"*)
                echo "$MOBILE_GENERATOR_LINE_PREFIX : iOS platform was already instaled. Removing and installing it afresh for avoiding run time errors..."
                remove_ios_platform=$(rm -rf ios 2>&1)
		if [ $? -gt 0 ]; then
			echo "$MOBILE_GENERATOR_LINE_PREFIX : Error adding iOS platform - unable delete previously installed iOS platform! The error details are displayed below."
		    	echo "$MOBILE_GENERATOR_LINE_PREFIX : Aborting $MOBILE_GENERATOR_NAME unimobile build and run script."
		    	echo "$MOBILE_GENERATOR_LINE_PREFIX : Please retry running this script after fixing these errors."
		    	echo "----------------------------------------------------------------------------------------------------------------------------------------------------------------"
			echo "$remove_ios_platform"
			echo "----------------------------------------------------------------------------------------------------------------------------------------------------------------"
		    	exit $EXIT_IONIC_CAP_ADD_PLATFORM_COMMAND_ERROR_CODE
		fi
                ADD_CAPACITOR_IOS_PLATFORM=$(ionic cap add ios 2>&1)
                if [ $? -gt 0 ]; then
			echo "$MOBILE_GENERATOR_LINE_PREFIX : Error adding iOS platform! The error details are displayed below."
			echo "$MOBILE_GENERATOR_LINE_PREFIX : Aborting $MOBILE_GENERATOR_NAME unimobile app build and run script!"
			echo "$MOBILE_GENERATOR_LINE_PREFIX : Please retry running this script after fixing these errors."
			echo "----------------------------------------------------------------------------------------------------------------------------------------------------------------"
			echo $ADD_CAPACITOR_IOS_PLATFORM
			echo "----------------------------------------------------------------------------------------------------------------------------------------------------------------"
			exit $EXIT_IONIC_CAP_ADD_PLATFORM_COMMAND_ERROR_CODE
                fi
            ;;
        esac
    fi
    echo "$MOBILE_GENERATOR_LINE_PREFIX : Installed capacitor iOS platform."   
}

clear
echo "=========================================================================================================================================="
echo 			"\t\tWelcome to $MOBILE_GENERATOR_NAME Unimobile app build and run script"
echo "Sit back, relax, and sip a cuppa coffee while the dependencies are downloaded, project is built, and run."
echo "Unless the execution of this script stops, do not be bothered nor worried about any warnings or errors displayed during the execution ;-)"
echo "=========================================================================================================================================="

# OS version validation
echo "$MOBILE_GENERATOR_LINE_PREFIX : Your MacOS version is : $(/usr/bin/sw_vers -productVersion)"
# Minimum version required is Big Sur - 11.0.1 due to Xcode 12+ requirement for ionic capacitor
if [[ $(/usr/bin/sw_vers -productVersion | awk -F. '{ print $1 }') -ge $OS_MAJOR_VERSION ]]; then
    if [[ $(/usr/bin/sw_vers -productVersion | awk -F. '{ print $2 }') -ge $OS_MINOR_VERSION ]]; then
        if [[ $(/usr/bin/sw_vers -productVersion | awk -F. '{ print $3 }') -ge $OS_PATCH_VERSION ]]; then
            echo "$MOBILE_GENERATOR_LINE_PREFIX : MacOS version requirement - $OS_MAJOR_VERSION.$OS_MINOR_VERSION.$OS_PATCH_VERSION - met, moving ahead with other checks..."
        else
            echo "$MOBILE_GENERATOR_LINE_PREFIX : You are running non-supported MacOS version $(/usr/bin/sw_vers -productVersion)!"
            echo "$MOBILE_GENERATOR_LINE_PREFIX : Minimum required version is $OS_MAJOR_VERSION.$OS_MINOR_VERSION.$OS_PATCH_VERSION"
            echo "$MOBILE_GENERATOR_LINE_PREFIX : Aborting the build process!"            
            exit $EXIT_MACOS_VERSION_CHECK_COMMAND_ERROR_CODE
        fi
    else
        echo "$MOBILE_GENERATOR_LINE_PREFIX : You are running non-supported MacOS version $(/usr/bin/sw_vers -productVersion)!"
        echo "$MOBILE_GENERATOR_LINE_PREFIX : Minimum required version is $OS_MAJOR_VERSION.$OS_MINOR_VERSION.$OS_PATCH_VERSION"
        echo "$MOBILE_GENERATOR_LINE_PREFIX : Aborting the build process!"        
        exit $EXIT_MACOS_VERSION_CHECK_COMMAND_ERROR_CODE
    fi
else
    echo "$MOBILE_GENERATOR_LINE_PREFIX : You are running non-supported MacOS version $(/usr/bin/sw_vers -productVersion)!"
    echo "$MOBILE_GENERATOR_LINE_PREFIX : Minimum required version is $OS_MAJOR_VERSION.$OS_MINOR_VERSION.$OS_PATCH_VERSION"
    echo "$MOBILE_GENERATOR_LINE_PREFIX : Aborting the build process!"    
    exit $EXIT_MACOS_VERSION_CHECK_COMMAND_ERROR_CODE
fi

# Xcode version validation
if [[ $(/usr/bin/xcodebuild -version | awk 'NR==1{print $2}' | awk -F. '{print $1}') -ge XCODE_MAJOR_VERSION ]]; then
    if [[ $(/usr/bin/xcodebuild -version | awk 'NR==1{print $2}' | awk -F. '{print $2}') -ge XCODE_MINOR_VERSION ]]; then
        if [[ $(/usr/bin/xcodebuild -version | awk 'NR==1{print $2}' | awk -F. '{print $3}') -ge XCODE_PATCH_VERSION ]]; then
            echo "$MOBILE_GENERATOR_LINE_PREFIX : Xcode version requirement - $XCODE_MAJOR_VERSION.$XCODE_MINOR_VERSION.$XCODE_PATCH_VERSION - met, moving ahead with other checks..."
        else
            echo "$MOBILE_GENERATOR_LINE_PREFIX : You are running non-supported Xcode version $(/usr/bin/xcodebuild -version | awk 'NR==1{print $2}')!"
            echo "$MOBILE_GENERATOR_LINE_PREFIX : Minimum required version is $XCODE_MAJOR_VERSION.$XCODE_MINOR_VERSION.$XCODE_PATCH_VERSION"
            echo "$MOBILE_GENERATOR_LINE_PREFIX : Aborting the build process!"            
            exit $EXIT_XCODE_VERSION_CHECK_COMMAND_ERROR_CODE
        fi
    else
        echo "$MOBILE_GENERATOR_LINE_PREFIX : You are running non-supported Xcode version $(/usr/bin/xcodebuild -version | awk 'NR==1{print $2}')!"
        echo "$MOBILE_GENERATOR_LINE_PREFIX : Minimum required version is $XCODE_MAJOR_VERSION.$XCODE_MINOR_VERSION.$XCODE_PATCH_VERSION"
        echo "$MOBILE_GENERATOR_LINE_PREFIX : Aborting the build process!"        
        exit $EXIT_XCODE_VERSION_CHECK_COMMAND_ERROR_CODE
    fi
else
    echo "$MOBILE_GENERATOR_LINE_PREFIX : You are running non-supported Xcode version $(/usr/bin/xcodebuild -version | awk 'NR==1{print $2}')!"
    echo "$MOBILE_GENERATOR_LINE_PREFIX : Minimum required version is $XCODE_MAJOR_VERSION.$XCODE_MINOR_VERSION.$XCODE_PATCH_VERSION"
    echo "$MOBILE_GENERATOR_LINE_PREFIX : Aborting the build process!"    
    exit $EXIT_XCODE_VERSION_CHECK_COMMAND_ERROR_CODE
fi

# xcode-select command tools verification
if [[ $(xcode-select --version | awk '{ print $3 }') < $XCODE_SELECT_MIN_VERSION ]]; then
    echo "$MOBILE_GENERATOR_LINE_PREFIX : You are running non-supported xcode-select version $(xcode-select --version | awk '{ print $3 }' | awk -F. '{ print $1 }')!"
    echo "$MOBILE_GENERATOR_LINE_PREFIX : Minimum required version is $XCODE_SELECT_MIN_VERSION+"
    echo "$MOBILE_GENERATOR_LINE_PREFIX : Aborting the build process!"    
    exit $EXIT_XCODE_SELECT_VERSION_CHECK_COMMAND_ERROR_CODE
else
    echo "$MOBILE_GENERATOR_LINE_PREFIX : xcode-select version requirement - $XCODE_SELECT_MIN_VERSION - met, moving ahead with other checks..."
fi

# Node install check
node_command=$(node --version 2>&1)
if [ $? -gt 0 ]; then
	echo "$MOBILE_GENERATOR_LINE_PREFIX : Nodejs is not installed!"
	echo "$MOBILE_GENERATOR_LINE_PREFIX : Please install a stable and LTS version of nodejs major release $NODE_MAJOR_VERSION and retry running this script."    
	exit $EXIT_NODE_VERSION_CHECK_COMMAND_ERROR_CODE
fi

# Node version check
node_version=$(node --version | awk -F. '{ print $1 }')
node_command=${node_version#?}
if [ $node_command -lt $NODE_MAJOR_VERSION ]; then
    echo "$MOBILE_GENERATOR_LINE_PREFIX : You are running non-supported Node major version $(node --version | awk -F. '{ print $1 }')!"
    echo "$MOBILE_GENERATOR_LINE_PREFIX : Minimum required version is $NODE_MAJOR_VERSION+"
    echo "$MOBILE_GENERATOR_LINE_PREFIX : Aborting the build process. Please install a stable and LTS NodeJS release of major version $NODE_MAJOR_VERSION and retry running this script."    
    exit $EXIT_NODE_VERSION_CHECK_COMMAND_ERROR_CODE
else
    echo "$MOBILE_GENERATOR_LINE_PREFIX : Node version requirement - $NODE_MAJOR_VERSION - met, moving ahead with other checks..."
fi

# npm install check
npm_command=$(npm --version 2>&1)
if [ $? -gt 0 ]; then
	    echo "$MOBILE_GENERATOR_LINE_PREFIX : npm (Node Package Manager) is not installed!"
	    echo "$MOBILE_GENERATOR_LINE_PREFIX : Please install a stable and LTS version of npm major release $NPM_MAJOR_VERSION+ and retry running this script."    
	    exit $EXIT_NPM_VERSION_CHECK_COMMAND_ERROR_CODE
fi

# npm version check
if [[ $(npm --version | awk -F. '{ print $1 }') -lt $NPM_MAJOR_VERSION ]]; then
    echo "$MOBILE_GENERATOR_LINE_PREFIX : You are running non-supported NPM major version $(npm --version | awk -F. '{ print $1 }')!"
    echo "$MOBILE_GENERATOR_LINE_PREFIX : Minimum required major NPM version is $NPM_MAJOR_VERSION+"
    echo "$MOBILE_GENERATOR_LINE_PREFIX : Aborting the build process. Please install a stable and LTS NPM release of major version $NPM_MAJOR_VERSION and retry running this script."
    exit $EXIT_NPM_VERSION_CHECK_COMMAND_ERROR_CODE
else
    echo "$MOBILE_GENERATOR_LINE_PREFIX : NPM major version requirement - $NPM_MAJOR_VERSION - met, moving ahead with other checks..."
fi

# cocoapods install check
cocoapods_command=$(pod --version 2>&1)
if [ $? -gt 0 ]; then
	    echo "$MOBILE_GENERATOR_LINE_PREFIX : Cocoapods is not installed!"
	    echo "$MOBILE_GENERATOR_LINE_PREFIX : Please install cocoapods and retry running this script."    
	    exit $EXIT_COCOAPADS_VERSION_CHECK_COMMAND_ERROR_CODE
fi

# cocoapods version check
if [[ $(pod --version | awk -F. '{ print $1 }') -lt $COCOAPODS_MAJOR_VERSION ]]; then
    echo "$MOBILE_GENERATOR_LINE_PREFIX : Cocoapods is not installed or a non-supported version $(pod --version | awk -F. '{ print $1 }')!"
    echo "$MOBILE_GENERATOR_LINE_PREFIX : Minimum required version is $COCOAPODS_MAJOR_VERSION+"
    echo "$MOBILE_GENERATOR_LINE_PREFIX : Aborting the build process!"    
    exit $EXIT_COCOAPADS_VERSION_CHECK_COMMAND_ERROR_CODE
else
    echo "$MOBILE_GENERATOR_LINE_PREFIX : Cocoapods version requirement - $COCOAPODS_MAJOR_VERSION - met, moving ahead with other checks..."
fi

# ionic install check
ionic_command=$(ionic --version 2>&1)
if [ $? -gt 0 ]; then
    echo "$MOBILE_GENERATOR_LINE_PREFIX : Ionic CLI is not installed!"
    echo "$MOBILE_GENERATOR_LINE_PREFIX : Please install a stable and LTS version of Ionic CLI version $IONIC_CLI_MAJOR_VERSION.$IONIC_CLI_MINOR_VERSION or greater and retry running this script."    
    exit $EXIT_IONIC_CLI_VERSION_CHECK_COMMAND_ERROR_CODE
fi

# ionic cli version validation
if [[ $(ionic --version | awk -F. '{ print $1 }') -lt $IONIC_CLI_MAJOR_VERSION ]]; then
    echo "$MOBILE_GENERATOR_LINE_PREFIX : You are running non-supported Ionic CLI major version $(ionic --version | awk -F. '{ print $1 }')!"
    echo "$MOBILE_GENERATOR_LINE_PREFIX : Minimum required version is $IONIC_CLI_MAJOR_VERSION.$IONIC_CLI_MINOR_VERSION"
    echo "$MOBILE_GENERATOR_LINE_PREFIX : Aborting the build process!"    
    echo "$MOBILE_GENERATOR_LINE_PREFIX : Please install a stable and LTS version of Ionic CLI version $IONIC_CLI_MAJOR_VERSION.$IONIC_CLI_MINOR_VERSION or greater and retry running this script."    
    exit $EXIT_IONIC_CLI_VERSION_CHECK_COMMAND_ERROR_CODE
else
    echo "$MOBILE_GENERATOR_LINE_PREFIX : Ionic CLI version requirement - $IONIC_CLI_MAJOR_VERSION - met, moving ahead with other checks..."
fi

echo "$MOBILE_GENERATOR_LINE_PREFIX : Build environment validation completed successfully. Moving ahead with building and running your iOS application..."
unimo_install_ionic_deps_build_and_platform
if [ $? -gt 0 ]; then  
    exit $EXIT_IONIC_BUILD_COMMAND_ERROR_CODE
fi

# splash and app icon resources creation
echo "$MOBILE_GENERATOR_LINE_PREFIX : Customizing Unimobile application icon and splash images..."
CORDOVA_RES_GEN_ICON_SPLASH=$(cordova-res ios --skip-config --copy 2>&1)
if [ $? -gt 0 ]; then
    # check for execution error and follow-up with any remedial actions
    echo "$MOBILE_GENERATOR_LINE_PREFIX : Error customizing the application icon and splash images!"
    echo "$MOBILE_GENERATOR_LINE_PREFIX : The error is:"     
    echo "----------------------------------------------------------------------------------------------------------------------------------------------------------------------"
    echo $CORDOVA_RES_GEN_ICON_SPLASH
    echo "----------------------------------------------------------------------------------------------------------------------------------------------------------------------"
    echo "$MOBILE_GENERATOR_LINE_PREFIX : Aborting $MOBILE_GENERATOR_NAME unimobile app build and run script!"
    echo "$MOBILE_GENERATOR_LINE_PREFIX : Please retry running $MOBILE_GENERATOR_NAME build and run script after deleting the node_modules, ios, and www directories in this project folder, if they exist."      
    exit $EXIT_CORDOVA_RES_COMMAND_ERROR_CODE  
fi
echo "$MOBILE_GENERATOR_LINE_PREFIX : Customized Unimobile application icon and splash images."

echo "$MOBILE_GENERATOR_LINE_PREFIX : Starting iOS simulator for running the Unimobile app..."
if !(ionic cap run ios); then
    echo "$MOBILE_GENERATOR_LINE_PREFIX : Error running iOS simulator and running your iOS application. Aborting appbrahma build and run script!"
    echo "$MOBILE_GENERATOR_LINE_PREFIX : Please retry running $MOBILE_GENERATOR_NAME build and run script after deleting the node_modules, ios, and www directories in this project folder, if exist."    
    exit $EXIT_IONIC_CAP_RUN_COMMAND_ERROR_CODE
fi

# display credentials for log in - for server integrated template
echo "$MOBILE_GENERATOR_LINE_PREFIX : Please use the below login credentials to log into the appbrahma generated server from front-end unimobile app after running the backend server in a seperate terminal/console along with DB server as chosen in your application configuration for generation"
echo "\tUsername: brahma"
echo "\tPassword: brahma@appbrahma"
