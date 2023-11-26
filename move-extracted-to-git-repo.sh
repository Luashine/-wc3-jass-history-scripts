#!/usr/bin/env bash

# What is it:
# Use this script after (semi-manually) extracting files from online storage using CascView
# This script will then rename and copy the extract-folders with original files to the
# jass-history repository
# All you need to do after is to add the names to sorted list

# USAGE:

# ./script <path/to/move/to/parent-folder/> <extract-w3-1.33.0.19378-e94d62c> [extract2] [...]

set -e

moveToFolder="$1"
shift;

function echoerr() {
	>&2 echo "$@";
}

if [[ ! -d "$moveToFolder" ]]; then
	echoerr "moveToFolder is not a directory: '$moveToFolder'"
fi

for extractionFolder in "$@"; do
	extrW3mod="${extractionFolder}/war3.w3mod"

	if [[ ! -d "$extractionFolder" ]]; then
		echoerr "Target is not a folder: '$extractionFolder'"
		exit 2;
	fi

	if [[ ! -d "${extrW3mod}" ]]; then
		echoerr "Target is empty or is from old game version, not found: '${extrW3mod}'"
		exit 2
	fi

	if [[ "$(find "$extractionFolder" -type f | wc -l)" -eq 0 ]]; then
		echoerr "No files found in target: '$extractionFolder'"
		exit 2
	fi

	# extract-w3-1.32.3.14857-f98d8b1

	step1="${extractionFolder##extract-}" # w3-1.32.3.14857-f98d8b1
	branchName="${step1%%-*}" # w3
	cdnIdShort="${step1##*-}" # f98d8b1

	step2="${step1%-*}" # w3-1.32.3.14857
	gameVer="${step2##*-}" # 1.32.3.14857
	gameVerMajor="${gameVer%%.*}"
	gameVerStep1="${gameVer#*.}"
	gameVerMinor="${gameVerStep1%%.*}"

	fancyName="unknown"

	if [[ "$gameVerMajor" -gt 1 ]] || [[ ( "$gameVerMajor" -eq 1 ) && ( "$gameVerMinor" -ge 32 ) ]]; then
		fancyName="Reforged"
	fi

	jassHistoryDirName="${fancyName}-v${gameVer}-${branchName}-${cdnIdShort}"
	newGameDataDir="$moveToFolder/${jassHistoryDirName}"

	printf "branch=%-3s, ver=%-13s, cdnid=%-7s...\n" "$branchName" "$gameVer" "$cdnIdShort"

	if [[ -d "$newGameDataDir" ]]; then
		echoerr "Folder in move target already exists: '$newGameDataDir'"
		exit 3
	fi

	echo "$jassHistoryDirName"

	mkdir "$newGameDataDir"
	cp --interactive --preserve=all -r -- "$extrW3mod"/* "$newGameDataDir"
	echo "Copied successfully."
	echo;
done
