#!/usr/bin/env bash
set -e # Script exists on the first failure
set -x # For debugging purpose

function usage () {
    cat <<USAGE
    
    Usage: $0 [args]

    Options:
        -s, --server-version        Select FileMaker Server Version

        -d, --deployment-options    Set FMS deployment options

        -u, --admin-user            Set admin console user
        -p, --admin-password        Set admin console password
        -i, --admin-pin             Set admin console pin

        -l, --license-path          Define a path to a license certificate

        ----------------------------------------------------
        -h, --help, --usage:    	Print this help message.
        -v, --version               Get this script version
    

    -s, --server-version)
        This defines the version of FileMaker Server. This version number
        is used to download a copy of FMS from Claris so it must be the full
        version number. You can find this by going to your Claris download
        page and hovering over the link for the FMS download. The full
        download URL should look something like:
        "https://downloads.claris.com/esd/fms_19.4.2.204.zip"
        We are concerned about the version number at the end of the URL.
        Ex: '19.4.2.204'

    The following options define values set in the 'Assisted Install.txt' file.
    For details, please see: 
    https://help.claris.com/en/server-network-install-setup-guide/content/customize-personalization-file.html

    -d, --deployment-options)
        Type one of the following after Deployment Options:

        0 (zero) to install a server machine (default)
        1 (one) to install a Claris FileMaker WebDirect™ secondary machine

        From Claris:
        If you are setting up a multiple-machine deployment, you need to provide 
        an Assisted Install.txt file for installing on the primary machine and 
        an Assisted Install.txt file for installing on the FileMaker WebDirect 
        secondary machines.

        Leave this set to 0 if you are uncertain which option to go with.

    -u, --admin-user)
        The user name to be used for signing in to Admin Console as the 
        server administrator. The user name is not case sensitive. If you enter 
        no value, the default user name admin is used.

    -p, --admin-password)
        The password to be used for signing in to Admin Console as the server 
        administrator. The password is case sensitive.
        If no password is provided, the password will be set to:
        NotSoStrongPassword

    -i, --admin-pin)
        The four-digit PIN value to be used in the command line interface (CLI) 
        for resetting the Admin Console password.
        If no PIN is provided, the PIN will be set to:
        1234

    -l, --license-path)
        The fully qualified path for the license certificate file.
        For example:
        Linux: /home/user name/Downloads/LicenseCert.fmcert

        Notes:
        If you omit the path for the FileMaker license certificate, the installer 
        looks for a file with the filename extension .fmcert in the following paths:
        - The default Downloads folder on the machine where the installer is located
            Linux: /home/user name/Downloads
        - The installer folder (the folder where the installer is located)
        - The LicenseFile folder:
            Linux: /opt/FileMaker/FileMaker Server/CStore/LicenseFile 
            on the machine where FileMaker Server is being installed

USAGE
    exit 1
}

function version () {
    cat <<VERSION
    FileMaker Server Preperation Script
    ---
    Version: 0.1 
    Production State: Alpha

    The purpose of this script is to assist in the preparation of deployment
    for FileMaker Server on Debian Linux. This is especially helpful and 
    purposely designed with containerization in mind.

VERSION
}

# Get flags
while [ "$1" != "" ]; do
    case $1 in
        -s | --server-version)
            shift
            FMS_VERSION=$1
            ;;

        -d | --deployment-options)
            shift
            DEPLOYMENT_OPTIONS=$1
            ;;

        -u | --admin-user)
            shift
            ADMIN_USER=$1
            ;;
        
        -p | --admin-password)
            shift
            ADMIN_PASSWORD=$1
            ;;
        
        -i | --admin-pin)
            shift
            ADMIN_PIN=$1
            ;;

        -l | --license-path)
            shift
            LICENSE_PATH=$1
            ;;

        -v | --version)
            version
            exit 1
            ;;

        -h | --help | --usage)
    		usage
    		exit 1
    		;;

    	*)
		    printf "\033[1;31mError: Invalid option!\033[0m\n"
    		usage
    		exit 1
    		;;

    esac
    shift
done

# Check for required flags
function requiredFlags () {
    if [ "$FMS_VERSION" = "" ]; then
       printf "\033[1;31mError: FileMaker Server version must be set!\033[0m\n"
       echo "Ex: '19.4.2.204' See help page for more detail"
       echo "fmsprep.sh --help"
       exit 1
    fi
}
requiredFlags

# Set undefined options to default
function setDefaultOptions () {
    if [ "$DEPLOYMENT_OPTIONS" = "" ]; then
        DEPLOYMENT_OPTIONS=${DEPLOYMENT_OPTIONS:-0}
    fi

    if [ "$ADMIN_USER" = "" ]; then
        ADMIN_USER=${ADMIN_USER:-admin}
    fi

    if [ "$ADMIN_PASSWORD" = "" ]; then
        ADMIN_PASSWORD=${ADMIN_PASSWORD:-NotSoStrongPassword}
    fi

    if [ "$ADMIN_PIN" = "" ]; then
        ADMIN_PIN=${ADMIN_PIN:-1234}
    fi
}
setDefaultOptions

# Make sure responses are valid.
function responseValidation () {
    echo "Response Validation is a WIP"
}

# Get local envirnment and create directories
function createEnv () {
    mkdir -p $PWD/fms/download
    mkdir -p $PWD/fms/install
}
createEnv

# Download FileMaker Server from Claris
function getFileMakerServer () {
    curl https://downloads.claris.com/esd/fms_${FMS_VERSION}.zip \
        --output $PWD/fms/download/fms_${FMS_VERSION}.zip \
        --fail 
        # --stderr downloadError.log
    
    if [ $? != 0 ]; then
        echo "Error: The FileMaker Server download failed. See downloadError.log for details."
        exit 1
    fi

    echo "FMS Download from Claris successful."

}

# Extract zip
function extractServer () {
    unzip $PWD/fms/download/fms*.zip -d $PWD/fms/install
}

# Check for cached version of FileMaker Server
function checkCached () {
    if [ -f "$PWD/fms/download/fms_${FMS_VERSION}.zip" ]; then
            DOWNLOAD_CACHED=TRUE
        else
            DOWNLOAD_CACHED=FALSE
    fi
    # echo $DOWNLOAD_CACHED
}

# Cleanup old install
function cleanOld () {
    rm $PWD/fms/install/*
}

# Make the magic happen
function makeReady () {
    checkCached
    if [ $DOWNLOAD_CACHED = TRUE ]; 
        then
            cleanOld
            extractServer
        else
            getFileMakerServer
            extractServer
    fi
}

makeReady

echo "FMS Prep successfull"
exit 0