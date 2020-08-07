#!/bin/bash
# sync3d.sh
#
# Convenience script for syncing gcode files with an SD card and/or Octoprint.
#
# @author Schuyler Martin <https://github.com/schuylermartin45>
#

declare -r USAGE="USAGE: ./sync3d.sh [sd|octo]"
declare -A OPTS=( ["sd"]=0 ["octo"]=1 )

# Wraps rsync to target a specific SRC and DST.
# 
# $1: Source directory
# $2: Destination directory
function syncWrapper {
    # Ensure trailing `/` on the source directory so that the destination is
    # copied-to directly (i.e. `files/*` -> `dst/` creates `dst/*` not
    # `dst/files/*`)
    src="${1}"
    [[ "${src}" != */ ]] && src="${src}/"
    rsync -zarvm --delete-excluded --include "*/" --include="*.gcode" --exclude="*" "${src}" "${2}"
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

    # Calc paths
    declare -r sdMountPt=$(mount | grep "${PRINTER_SD_CARD_NAME}" | awk '{ print $3 }')
    declare -r octoDstDir="${OCTOPRINT_USER_NAME}@${OCTOPRINT_SERVER_IP}:~/.octoprint/uploads/"
    
    # Bail if no path is found, as a safety measure
    if [ ! -d "${sdMountPt}" ]; then
        echo "Failed to find SD card named '${PRINTER_SD_CARD_NAME}'"
        exit 3
    fi

    # Sync based on the provided flags (by negating against the other flag)
    if [ "${1}" != "octo" ]; then
        echo "Syncing to SD card..."
        syncWrapper "${PRINTER_FILES_DIR}" "${sdMountPt}"
    fi
    if [ "${1}" != "sd" ]; then
        echo "Syncing up to Octoprint..."
        syncWrapper "${PRINTER_FILES_DIR}" "${octoDstDir}"
    fi
    echo "Done!"
}

main "${@}"
