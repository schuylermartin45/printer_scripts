#!/bin/bash
# sync3d.sh
#
# Convenience script for syncing gcode files with an SD card and/or Octoprint.
#
# @author Schuyler Martin <https://github.com/schuylermartin45>
#

declare -r USAGE="USAGE: ./sync3d.sh [sd|octo|remote]"
declare -A OPTS=( ["sd"]=0 ["octo"]=1 ["remote"]=2 )

# Wraps rsync to target a specific SRC and DST.
# 
# $1: Source directory
# $2: Destination directory
# $3: Inclusion file pattern
function syncWrapper {
    src="${1}"
    # Ensure trailing `/` on the source directory so that the destination is
    # copied-to directly (i.e. `files/*` -> `dst/` creates `dst/*` not
    # `dst/files/*`)
    [[ "${src}" != */ ]] && src="${src}/"
    include="${3}"
    # Default to copying only gcode files
    [[ -z "${include}" ]] && include="*.gcode"
    rsync -zarvm --delete-excluded --modify-window=2 --include "*/" --include="${include}" --exclude="*" "${src}" "${2}"
}

####    MAIN     ####
function main {
    # Usage checks
    if [ "$#" -gt 1 ]; then
        echo ${USAGE}
        exit 1
    fi
    if [ -n "$1" ] && [ -v ${OPTS[${1}]} ]; then
        echo ${USAGE}
        exit 2
    fi
    if [[ -z "${PRINTER_FILES_DIR}" ]]; then
        echo "Environment variable 'PRINTER_FILES_DIR' must be set."
        exit 4
    fi

    # Calc paths
    declare -r sdMountPt=$(mount | grep "${PRINTER_SD_CARD_NAME}" | awk '{ print $3 }')
    declare -r sdHwdPath=$(mount | grep "${PRINTER_SD_CARD_NAME}" | awk '{ print $1 }')
    declare -r octoDstDir="${OCTOPRINT_USER_NAME}@${OCTOPRINT_SERVER_IP}:~/.octoprint/uploads/"
    declare -r remoteDstDir="${SSH_REMOTE_USER_NAME}@${SSH_REMOTE_SERVER_IP}:${SSH_REMOTE_FILES_DIR}"
    
    # Concat all the environment variables in a subset into one string to act
    # act as a boolean check later.
    declare -r hasSD="${PRINTER_SD_CARD_NAME}"
    declare -r hasOcto="${OCTOPRINT_USER_NAME}${OCTOPRINT_SERVER_IP}"
    declare -r hasRemote="${SSH_REMOTE_USER_NAME}${SSH_REMOTE_SERVER_IP}${SSH_REMOTE_FILES_DIR}"

    # Sync based on available environment vars and override flags
    if [[ "${1}" == "sd" ]] || [[ -z "${1}" && ! -z "${hasSD}" ]]; then
        # Bail if no path is found, as a safety measure
        if [ ! -d "${sdMountPt}" ]; then
            echo "Failed to find SD card named '${PRINTER_SD_CARD_NAME}'"
            exit 3
        fi

        echo "Syncing to SD card..."
        syncWrapper "${PRINTER_FILES_DIR}" "${sdMountPt}"
        if command -v udisksctl &> /dev/null; then
            udisksctl unmount -b "${sdHwdPath}"
            udisksctl power-off -b "${sdHwdPath}"
            echo "########## SD UNMOUNTED. SAFE TO REMOVE! ##########"
        fi
    fi
    if [[ "${1}" == "octo" ]] || [[ -z "${1}" && ! -z ${hasOcto} ]]; then
        echo "Syncing up to Octoprint..."
        syncWrapper "${PRINTER_FILES_DIR}" "${octoDstDir}"
    fi
    if [[ "${1}" == "remote" ]] || [[ -z "${1}" && ! -z ${hasRemote} ]]; then
        echo "Syncing up to remote server..."
        syncWrapper "${PRINTER_FILES_DIR}" "${remoteDstDir}" "*"
    fi
    echo "Done!"
}

main "${@}"
