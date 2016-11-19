#!/bin/bash

# This script does one thing and one thing only: given a PO or POT filename, it
# adds a 'X-Git-Ref' header (or updates the existing header) with the current
# git HEAD's SHA. If it can't add the header for any reason, it prints a message
# on stderr and exits nonzero.
#
# All of the real work is just a few lines in the addAfterLine and addGitSha
# functions; the rest of the script is checking for error conditions.

FIELD_NAME='X-Git-Ref'
PREVIOUS_FIELD='Project-Id-Version'
COMMIT_HEADER_REGEX="^\"$FIELD_NAME:\s*[a-zA-Z0-9]*\s*\\\\n\"\s*$"

function addAfterLine { # filename target_line new_line
  local file="$1" target_line="$2" new_line="$3"
  sed -i -e "/^$target_line\s*$/a $new_line" "$file"
}

function addGitSha { # POx_file
  local pot_file="$1" sha=$(git rev-parse HEAD)
  addAfterLine "$pot_file" "\\\"$PREVIOUS_FIELD:.*\\\"" "\"$FIELD_NAME: $sha\\\\n\""
}

## Main
## ====

set -eo pipefail

pot_file="$1"

set -u # there should be no more undefined variables

if [[ -z "$pot_file" ]]; then
  echo "ERROR: no PO or POT file given" 1>&2
  echo "usage: $0 <po-or-pot-file>" 1>&2
  exit 1
fi

if [[ ! -e "$pot_file" ]]; then
  echo "ERROR: the file '$pot_file' does not exist" 1>&2
  exit 1
fi

if [[ ! -r "$pot_file" ]]; then
  echo "ERROR: don't have permission to open file '$pot_file'" 1>&2
  exit 1
fi

## if there's a commit header in there already, remove it
if [[ ! -z "$(grep "$COMMIT_HEADER_REGEX" "$pot_file")" ]]; then
  sed -i "/$COMMIT_HEADER_REGEX/d" "$pot_file"
fi

if ! grep "$PREVIOUS_FIELD" "$pot_file"; then
  echo "ERROR: the $FIELD_NAME header must follow the $PREVIOUS_FIELD header, but no" 1>&2;
  echo "$PREVIOUS_FIELD header was found in '$pot_file'" 1>&2;
  exit 1
fi

addGitSha "$pot_file"

if ! grep "$FIELD_NAME" "$pot_file"; then
  echo "ERROR: unable to add $FIELD_NAME header to '$pot_file' for unknown reasons." 1>&2;
  echo "Please file a bug report." 1>&2;
  exit 1
fi
