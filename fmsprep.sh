#!/usr/bin/env bash
set -e # Script exists on the first failure

### Help Function ###
function usage () {
    cat <<USAGE
    
    Usage: $0 [args]

    Options:
                    FileMaker Deployment Options
        ---------------------------------------------------- 
        -s, --server-version        Select FileMaker Server Version

        -d, --deployment-options    Set FMS deployment options

        -u, --admin-user            Set admin console user
        -p, --admin-password        Set admin console password
        -i, --admin-pin             Set admin console pin

        -l, --license-path          Define a path to a license certificate

                    Script Configuration Options
        ----------------------------------------------------
        --clean                     Cleanup cached files.
        --create-config             Generate Asisted Install file.
        --create-env                Explicitly create download and install
                                    locations.
        --debug                     Use 'set -x' for debugging.
        --download                  Download and extract FileMaker 
                                    Server from Claris.
        --download-only             Only download FileMaker Server.
        --env                       Use environment variables (Docker).
        --extract-only              Only extract FMS archieve.
        --install                   Install FileMaker Server.

                                Usage
        ----------------------------------------------------
        -h, --help, --usage:    	Print this help message.
        -v, --version               Get this script version.
    

    Filemaker Deployment Options:
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

    Script Configuration Options:
    --clean)
        Cleanup cached files. Removes files in the following locations:
            - fms/install/*

    --create-config)
        Generates 'Asisted Install.txt' file. This file is used to configure FileMaker
        Server for the first time.

    --create-env)
        Explicitly create download and install locations. This is used to ensure the script
        is running in the correct directory. Takes your current working directory and makes
        new directories in the following locations:
            - fms/install
            - fms/download

    --debug)
        Use 'set -x' for debugging. This will print out the commands being run.

    --download)
        Download and extract FileMaker Server from Claris. This will download the
        FMS archive from Claris and extract it to the 'fms/download' directory. Note that
        --version must be set.

    --download-only)
        Only download FileMaker Server. This will download the FMS archive from Claris
        and place it in the 'fms/download' directory. Note that --version must be set.

    --env)
        Use environment variables (Docker). This will use the environment variables
        to set the following variables:
            - LICENSE_ACCEPTED
            - DEPLOYMENT_OPTIONS
            - ADMIN_USER
            - ADMIN_PASSWORD
            - ADMIN_PIN
            - LICENSE_PATH
        Options can be set in the .env file or by using the command line option "-e"
        at run time.

    --extract-only)
        Only extract FMS archieve. This will extract the cached FMS archive from the
        'fms/download' directory to the 'fms/install' directory. Note: The script is 
        configured to only extract the debian package from the FMS archive. All other 
        files are ignored, including the documentation and the default assissted 
        install file.

    --install)
        Install FileMaker Server. This will install the FMS package from the 'fms/install'
        directory. The assissted install file is used to configure the server and must
        be located in the 'fms/install' directory. Everything from the 'fms/install'
        directory will be copied to /install before installation. Requires root privileges
        to create the /install directory and to install the FMS package.


USAGE
    exit 1
}

### Define Functions (Listed alphabetically)###

# Created 'Assisted Install.txt' config file
function assistedInstall () {
    cat <<EOF > $PWD/fms/install/'Assisted Install.txt'
[Assisted Install]

License Accepted=1

Deployment Options=$DEPLOYMENT_OPTIONS

Admin Console User=$ADMIN_USER

Admin Console Password=$ADMIN_PASSWORD

Admin Console PIN=$ADMIN_PIN

License Certificate Path=$LICENSE_PATH

EOF
}

# Check for cached version of FileMaker Server
function checkCached () {
    if compgen -G "$PWD/fms/download/fms*.zip" > /dev/null; then
            DOWNLOAD_CACHED=TRUE
        else
            DOWNLOAD_CACHED=FALSE
    fi
}

# Cleanup old install
function cleanOld () {
    rm $PWD/fms/install/*
}

# Get local envirnment and create directories
function createEnv () {
    mkdir -p $PWD/fms/download
    mkdir -p $PWD/fms/install
}

# Extract zip
function extractServer () {
    if ! command -v unzip &> /dev/null; then
        echo "Error: unzip program not installed on machine."
        echo "Install unzip. Ex: apt isntall unzip"
        exit 1
    else
        unzip -j $PWD/fms/download/fms*.zip *.deb -d $PWD/fms/install
    fi
}

# Download FileMaker Server from Claris
function getFileMakerServer () {
    # Check to make sure $FMS_VERSION is set
    if [ -z "$FMS_VERSION" ]; then
        echo "Error: FMS_VERSION is not set."
        echo "Set FMS_VERSION to the version of FileMaker Server you want to install."
        exit 1
    fi
    curl https://downloads.claris.com/esd/fms_${FMS_VERSION}.zip \
        --output $PWD/fms/download/fms_${FMS_VERSION}.zip \
        --fail #\
        #--stderr downloadError.log
    
    if [ $? != 0 ]; then
        echo "Error: The FileMaker Server download failed."
        exit 1
    fi
    echo "FMS Download from Claris successful."
}

# Install FileMaker Server using the 'Assisted Install.txt' file
function installServer () {
    if [ -f $PWD/fms/install/Assisted\ Install.txt ]; then
        echo "Installing FileMaker Server..."
        local FMS_PACKAGE_NAME=$(ls $PWD/fms/install/*.deb)
        
        # Check if user is root
        if [ "$EUID" -ne 0 ]; then
            local USER_ROOT=FALSE
        else
            local USER_ROOT=TRUE
        fi

        #Cache current working directory
        local CURRENT_DIR=$PWD

        # Install FileMaker Server
        if [ "$USER_ROOT" = "TRUE" ]; then
            mkdir /install
            cp $PWD/fms/install/* /install
            cd /install
            DEBIAN_FRONTEND=noninteractive
            FM_ASSISTED_INSTALL=/install apt install /install/*.deb
        else
            sudo mkdir /install
            sudo cp $PWD/fms/install/* /install
            sudo cd /install
            DEBIAN_FRONTEND=noninteractive
            sudo FM_ASSISTED_INSTALL=/install apt install /install/*.deb
        fi

    else
        echo "Error: The FileMaker Server installation failed. Assisted Install.txt file not found."
        exit 1
    fi
}

# Check for required flags
function requiredFlags () {
    if [ "$FMS_VERSION" = "" ]; then
       printf "\033[1;31mError: FileMaker Server version must be set!\033[0m\n"
       echo "Ex: '19.4.2.204' See help page for more detail"
       echo "fmsprep.sh --help"
       exit 1
    fi
}

# Make sure responses are valid.
function responseValidation () {
    echo "Response Validation is a WIP"
}

# Set undefined options to default
function setDefaultOptions () {
    if [ "$DEPLOYMENT_OPTIONS" = "" ]; then
        DEPLOYMENT_OPTIONS=${DEPLOYMENT_OPTIONS:-0}
    fi

    if [ "$ADMIN_USER" = "" ]; then
        ADMIN_USER=${ADMIN_USER:-admin}
    fi

    if [ "$ADMIN_PASSWORD" = "" ]; then
        ADMIN_PASSWORD=${ADMIN_PASSWORD:-password}
    fi

    if [ "$ADMIN_PIN" = "" ]; then
        ADMIN_PIN=${ADMIN_PIN:-1234}
    fi
}

function version () {
    cat <<VERSION
    FileMaker Server Preperation Script
    ---
    Version: 0.2 
    Production State: Alpha

    The purpose of this script is to assist in the preparation of deployment
    for FileMaker Server on Debian Linux. This is especially helpful and 
    purposely designed with containerization in mind.

VERSION
}

### Declare booleans ###
    declare CLEAN_OLD=FALSE
    declare CREATE_CONFIG=FALSE
    declare DOWNLOAD_AND_EXTRACT=FALSE
    declare DOWNLOAD_ONLY=FALSE
    declare EXTRACT_ONLY=FALSE
    declare USE_ENV=FALSE
    declare INSTALL_SERVER=FALSE
#

### Get user input ###
while [ "$1" != "" ]; do
    case $1 in
        # FileMaker Deployment Options
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

        # Script Configuration Options
        --clean)
            CLEAN_OLD=TRUE
            ;;

        --create-config)
            CREATE_CONFIG=TRUE
            ;;

        --create-env)
            createEnv
            ;;

        --debug)
            set -x # For debugging purposes
            ;;

        --download)
            DOWNLOAD_AND_EXTRACT=TRUE
            ;;

        --download-only)
            DOWNLOAD_ONLY=TRUE
            ;;

        --env)
            USE_ENV=TRUE
            ;;

        --extract-only)
            EXTRACT_ONLY=TRUE
            ;;

        --install)
            INSTALL_SERVER=TRUE
            ;;

        # Usage, Help, Version
        -h | --help | --usage)
    		usage
    		exit 1
    		;;

        -v | --version)
            version
            exit 1
            ;;

        # Unknown option
    	*)
		    printf "\033[1;31mError: Invalid option!\033[0m\n"
    		usage
    		exit 1
    		;;

    esac
    shift
done

### Clean install folder if user specified --clean ###
if [ $CLEAN_OLD == TRUE ];then
    echo "Cleaning up old files..."
    cleanOld
    echo "Done"
fi

### Only download FMS if user specified --download-only ###
if [ $DOWNLOAD_ONLY == TRUE ] && [ $DOWNLOAD_AND_EXTRACT != TRUE ];then
    requiredFlags
    createEnv
    echo "Downloading FileMaker Server from Claris..."
    getFileMakerServer

    elif [ $DOWNLOAD_ONLY == TRUE ] && [ $DOWNLOAD_AND_EXTRACT == TRUE ]; then
        echo "ERROR: --download-only and --download cannot be specified at the same time!"
        exit 1
fi

### Download and extract FMS if user specified --download ###
if [ $DOWNLOAD_AND_EXTRACT == TRUE ] && [ $DOWNLOAD_ONLY != TRUE ];then
    requiredFlags
    createEnv
    echo "Downloading FileMaker Server from Claris..."
    checkCached
    if [ $DOWNLOAD_CACHED == TRUE ];then
        echo "Download cached"
        elif [ $DOWNLOAD_CACHED == FALSE ];then
        getFileMakerServer
    fi
        
    echo "Extracting archieve..."
    extractServer
    echo "Done"
    elif [ $DOWNLOAD_ONLY == TRUE ] && [ $DOWNLOAD_AND_EXTRACT == TRUE ]; then
        echo "ERROR: --download-only and --download cannot be specified at the same time!"
        exit 1
fi


### Create config if user specified --create-config ###
if [ $CREATE_CONFIG == TRUE ];then
    echo "Generating Assisted Install.txt"
    createEnv
    if [ $USE_ENV == TRUE ];then
        echo "Using environment variables"
    else
        setDefaultOptions
    fi
    assistedInstall
    echo "Done"
fi

### Only extract the archive if user specified --extract-only ###
if [ $EXTRACT_ONLY == TRUE ] && [ $DOWNLOAD_AND_EXTRACT != TRUE ] && [ $DOWNLOAD_ONLY != TRUE ]; then
    echo "Checking for cached archive"
    checkCached
    if [ $DOWNLOAD_CACHED == FALSE ]; then echo "Download not cached. Please download FileMaker Server"; exit 1; fi
    extractServer

    elif [ $DOWNLOAD_AND_EXTRACT == TRUE ] || [ $DOWNLOAD_ONLY == TRUE ]; then
        echo "ERROR: --download-only and --download cannot be specified at the same time --extract only is specified!"
        exit 1
fi

### Install FileMaker Server if user specified --install ###
if [ $INSTALL_SERVER == TRUE ];then
    installServer
    echo "Done"
fi

echo "FMS Prep finished."

# End of script
exit 0