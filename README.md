# 3D Printer Scripts
A collection of scripts I use to manage my 3D printer.

I have a Prusa MK3S but most of these scripts are printer-agnostic.

## Dependencies
Here is a list of dependencies that these scripts use. I would also recommend
setting up ssh keys with the Octoprint server for easy-of-use.
- `rsync`
- `udisksctl`
  - If available, the SD card will be automatically unmounted.

### Compatibility Note
This was tested on a Ubuntu 20.04 LTS system. MacOS likely has different
variation of `rsync` and other utilities that may cause unexpected/untested
behavior.

## Required Environment Variables
To make these scripts portable and easily accessible to everyone, they depend
on a series of environment variables to be set for your custom configuration.

Set these in your shell's RC file as appropriate:

```bash
PRINTER_FILES_DIR           # Local disk directory storing printer files 
PRINTER_SD_CARD_NAME        # Name of the SD card used with the printer. This is
                            # not a path in case the path changes.

# Syncs to the octoprint default directory
OCTOPRINT_USER_NAME         # User name of Octoprint server
OCTOPRINT_SERVER_IP         # IP address of the Octoprint server

# Remote servers will back-up all files
SSH_REMOTE_USER_NAME        # User name of remote server (that you have SSH
                            # access too)
SSH_REMOTE_SERVER_IP        # IP Address of remote server
SSH_REMOTE_FILES_DIR        # Directory on remote server
```

Defining all required environment variables for an operating mode ensures the
mode will be run by default. This can be overridden by explicitly stating
a single mode.

For example, defining `SSH_REMOTE_*` and `PRINTER_*` will sync to those
destinations, but ignore syncing to an Octoprint server.


## sync3d
Syncs directory of 3D printer files to an SD card and/or Octoprint instance.
By default, this attempts to `rsync` to both.

### Usage
```bash
./sync3d.sh [sd|octo|remote]
```
