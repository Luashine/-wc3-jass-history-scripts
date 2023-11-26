#!/usr/bin/env bash

set -e

# Opening a multiple MPQs in merged mode

# MPQEditor.exe /merged BaseMpq1 BaseMpq2 BaseMpq3 ... BaseMpqN [/patch PatchMpq1 PatchMpq2 ... PatchMpqN] [/listfile ListFileName]

#Opens multiple MPQs in merged mode. The user will only see one tree,
#where all the files will be combined. This is how the game sees
#all MPQs. 

# 0. FOR EACH VERSION:

# 1. Open
# MPQEditor.exe /merged War3.mpq War3x.mpq /patch War3Patch.mpq War3local.mpq War3xlocal.mpq

# 2. Manually extract:
# /Custom_V0
# /Melee_V0
# /Scripts

# 3. Exit MPQEditor

# Go to 0.
echoerr "Loading configuration from current dir: $(pwd)"
source "config-extract-from-mpq.sh"

function isCygwin() {
	if [[ "$(uname -o)" = "Cygwin" ]]; then
		return 0
	else
		return 1
	fi
}

function mpqeditorSetExtractDir() {
	# Sets the path as Extraction dir in MPQEditor config

	# MPQEditor will create the folder automatically
	
	local extractPath="$1";
	local extractPathOsNative="$1"; # default is the passed path
	
	if [[ -z "$extractPath" ]]; then
		echoerr "mpqeditorSetExtractDir: extractPath is empty!"
		exit 2
	fi
	if [[ ! -d "$extractPath" ]]; then
		echoerr "mpqeditorSetExtractDir: '$extractPath' is expected to be a directory!"
		exit 2
	fi
	
	local iniPath;
	if isCygwin; then
		iniPath="$(cygpath --unix "$APPDATA\\MPQEditor.ini")"
		extractPathOsNative="$(cygpath --windows "$extractPath")"
	else
		echoerr "You are not running under Cygwin and I have no idea what the MPQ extraction path would be"
		echoerr "Please go to %appdata%/MPQEditor.ini (or in MPQEditor options) and set the path to"
		echoerr "$extractPath"
		echoerr "Then just delete the if-else in the script file."
	fi
	
	if [[ -f "$iniPath" ]]; then
		# TODO Security: Path must not contain |
		local pathBackslashEsc="${extractPathOsNative//\\/\\\\}"
		sed \
			-e 's|^ExtractPath=.*|ExtractPath='"${pathBackslashEsc}"'| ; s|ReadOnlyMode=false|ReadOnlyMode=true|' \
			"$iniPath" > "${iniPath}.new"
		
		mv "$iniPath" "${iniPath}.old"
		mv "${iniPath}.new" "$iniPath"
	else
		echoerr "Creating a new ini file for MPQEditor config!"
		printf "%s\n""ExtractPath=%s\n""ReadOnlyMode=%s\n" \
			"[Options]" "$extractPathOsNative" "true" \
			> "$iniPath"
		
	fi
}

function tarX() {
	local tarFile="$1"
	if [[ -z "$tarFile" ]]; then
		>&2 echo "tarX: tarFile is empty! Aborting"
		exit 1
	fi
	
	
	rm -rf --preserve-root=all -- "$tarExtractFolder" || true;
	if [[ ! -e "$tarExtractFolder" ]]; then
		mkdir "$tarExtractFolder" || exit 1
	fi
	tar --ignore-case --wildcards \
		--exclude '*.dll' \
		--exclude '*.exe' \
		--exclude '*.w3m' \
		--exclude '*.asi' \
		--exclude '*.m3d' \
		--exclude '*.flt' \
		--exclude '*.htm' \
		--exclude '*.html' \
		--exclude '*.css' \
		--exclude '*.js' \
		--exclude '*.jpg' \
		--exclude '*.log' \
		--exclude '*.txt' \
		--exclude '*.url' \
		--exclude '*.w3v' \
		--exclude '*.w3g' \
		--exclude '*.w3x' \
		--exclude '*.ico' \
		--exclude '*.manifest' \
		--exclude '*.wai' \
		--exclude '*.w3n' \
		--exclude '*/Movies' \
		--exclude '*.ax' \
		-xf "$1" --one-top-level="$tarExtractFolder"
}

function cdIntoAnyDir() {
	local dirpath="$1"
	if [[ -z "$dirpath" ]]; then
		>&2 echo "cdIntoAnyDir: dirpath not specified!"
		exit 2
	fi
	cd "$(find "$dirpath" -maxdepth 1 -type d ! -name '.')"
}

function echoerr() {
	>&2 echo "$@"
}

function processGameArchive() {
	# Arg1 = full path to game archive
	local exitCode=0
	local mpqEditorPid=-1337
	# ROC Beta:
	# war3beta.mpq
	#	war3beta_low.mpq
	#	war3beta_med.mpq
	# War3BetaPatch.mpq
	#	War3BetaPatch_low.mpq
	#	War3BetaPatch_med.mpq
	
	# ROC Release (RU):
	# war3.mpq
	#	War3patch.mpq / War3Patch.mpq
	
	# TFT Beta:
	# war3.mpq
	# war3x.mpq / War3x.mpq
	#	War3patch.mpq (yes, it patched on top of war3x)
	
	# TFT Release (RU):
	# war3.mpq
	# War3x.mpq (remained immutable)
	#	War3xlocal.mpq (remained immutable)
	#	War3Patch.mpq (changed from patch to patch)
	
	local baseMpqsAll=("war3beta.mpq" "war3.mpq" "war3x.mpq")
	local patchMpqsAll=("War3BetaPatch.mpq" "War3xlocal.mpq" "War3Patch.mpq")
	
	local baseMpqsCurrent=()
	local patchMpqsCurrent=()
	
	# TODO: Bug report
	# 'MPQEditor.exe' /merged war3beta.mpq war3.mpq war3x.mpq
	# Always puts "war3beta.mpq" last on the base file list
	
	local curArchivePath="$1"
	local curArchiveName="$(basename "$curArchivePath")"
	local curNameFancy="${curArchiveName%.*}" # removes path and last extension
	local mpqeditorExtractFolder="${tempRootFolder:-/tmp/mpqinvalidpath}/$curNameFancy"
	echo "Extract Path: '$mpqeditorExtractFolder'"
	
	cd "$tempRootFolder"
	tarX "$curArchivePath"
	cd "$tarExtractFolder"
	# we dont know what the parent folder is called like
	
	# could be Warcraft III or ROC Beta...
	printf "Currently in: '%s'\n" "$(pwd)";
	cdIntoAnyDir ".";
	printf "Jumped inside: '%s'\n" "$(pwd)";
	
	
	# MPQEditor throws an error if a specified MPQ file was not found
	for mpq in "${baseMpqsAll[@]}"; do
		if [[ -f "$mpq" ]]; then
			>&2 echo "Adding MPQ to base list: $mpq"
			baseMpqsCurrent+=("$mpq")
		fi
	done
	for mpq in "${patchMpqsAll[@]}"; do
		if [[ -f "$mpq" ]]; then
			>&2 echo "Adding MPQ to patch list: $mpq"
			patchMpqsCurrent+=("$mpq")
		fi
	done
	
	test ! -e "$mpqeditorExtractFolder" && mkdir "$mpqeditorExtractFolder"
	echoerr "Patching MPQEditor config"
	mpqeditorSetExtractDir "$mpqeditorExtractFolder"
	
	echoerr "Starting MPQEditor..."
	if [[ "${#baseMpqsCurrent[@]}" -eq 0 ]]; then
		echoerr "base MPQ list is empty, nothing found!"
		>&2 printf "Current folder: %s" "$(pwd)"
		exit 4
	fi
	exitCode=0
	if [[ "${#patchMpqsCurrent[@]}" -eq 0 ]]; then
		echoerr "Patch MPQ list is empty..."
		
		"$mpqeditor" /merged "${baseMpqsCurrent[@]}" & # continue with macro
	else
		"$mpqeditor" /merged "${baseMpqsCurrent[@]}" /patch "${patchMpqsCurrent[@]}" & # continue with macro
	fi
	mpqEditorPid=$!
	echoerr "MPQEditor PID: $mpqEditorPid"
	
	#echoerr "Press ENTER to start gui macro" && read;
	echoerr "Starting GUI Extraction macro"
	"$mpqeditor_gui_extract";
	exitCode=$?
	
	echoerr "The macro script quit with exit code = $exitCode"
	sleep 1
	if ps -p "$mpqEditorPid" > /dev/null; then
		echoerr "MPQEditor is still running, killing it."
		kill "$mpqEditorPid"
	else
		echoerr "MPQEditor not running."
	fi
	
	echoerr "Job's done!"
}


function main() {
	for gameArchivePath in "${ClassicArchivePath[@]}"; do
		echo "$gameArchivePath"
		processGameArchive "$gameArchivePath"
	done
}
main
