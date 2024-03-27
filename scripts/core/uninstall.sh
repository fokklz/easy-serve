#!/bin/bash
# Path: scripts/core/uninstall.sh
# Author: Fokko Vos
#
# Uninstalls the entire project
# This script will remove all services, volumes, and networks
# It will also remove all instances and their data,
# a backup will be created before removing anything
# The script will prompt for confirmation
#
# Flags:
#  --force: force the uninstallation without prompting for confirmation
#  --no-backup: do not backup the instances before uninstalling
