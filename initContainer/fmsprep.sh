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
done

# Validate flags required flags
function validateOptions () {
    if [ "$FMS_VERSION" = "" ]; then
       printf "\033[1;31mError: FileMaker Server version must be set!\033[0m\n"
       echo "See help page for more detail"
       echo "fmsprep.sh --help"
       exit 1
    fi
}

# Set undefined options to default
function setDefaultOptions () {
    if [ "$DEPLOYMENT_OPTIONS" = "" ]; then
        DEPLOYMENT_OPTIONS=${DEPLOYMENT_OPTIONS:-0}
    fi
}

# Get local envirnment and create directories
function createEnv () {
    mkdir -p $PWD/fms/download
    mkdir -p $PWD/fms/install
}
createEnv

# Download FileMaker Server from Claris



echo "FMS Prep successfull"
exit 0