#!/usr/bin/env bash

# Launches CascView in Online mode and sets a separate Extraction directory
# for the given CDN ID (game version) so the files are kept separate

# USAGE:
# Arg1 = Path to CascView.exe
# Arg2 = Path to CASC Cache
# Arg3 = Path to parent extraction folder
# Arg4 = CDN Geographical code (like 'eu' or us/cn/kr/tw/sg)
# Arg5 = CDN Config line in the format:
#2022-10-05-w3t.cfg:1.32.10.17020|931fc85d861c7ebb4dde1aa044f4ae9e|version-w3t-491204.bmime
# The important parts are the version, CDN ID and version-XX-12345.bmime

# EXAMPLE:

# launch-cascview-online.sh ./CascView.exe ~/temp/CascView-wc3-cache/ ~/temp/ "eu" '1.32.10.17093|80fa84d239ed941e842c4a57b1f54a70|version-w3t-1116994.bmime'


# CASCVIEW MANUAL:

# Example #3: CascView.exe /online C:\Work\w3*w3*eu*0836dab8d1f4bdb2cf61fe155de1ae7d

#Opens an online storage for Warcraft III (EU region), with Build Key
#set to 0836dab8d1f4bdb2cf61fe155de1ae7d.

###
set -e

cascViewPath="$1"
if [[ -z "$cascViewPath" ]] || [[ ! -f "$cascViewPath" ]]; then
	>&2 echo "CascView not found or not specified: '$cascViewPath'"
	exit 2
fi

cascCachePath="$2"
if [[ -z "$cascCachePath" ]] && [[ ! -d "$cascCachePath" ]]; then
	>&2 echo "CASC Cache path not found: '$cascCachePath'"
	exit 2
fi

extractionParentPath="$3"
if [[ -z "$extractionParentPath" ]] && [[ ! -d "$extractionParentPath" ]]; then
	>&2 echo "Extraction parent folder not found: '$extractionParentPath'"
	exit 2
else
	extractionParentPath="$(realpath "$extractionParentPath")"
	>&2 echo "Extracting in a subfolder of: '$extractionParentPath'"
fi

cdnGeo="$4"
if [[ -z "$cdnGeo" ]]; then
	>&2 echo "CDN Geo Code is empty!"
	exit 2
fi

cdnString="$5"
if [[ -z "$cdnString" ]]; then
	>&2 echo "CDN String is empty!"
else
	>&2 echo "Extracting CDN String: '$cdnString'"
	gameVer=""
	cdnId=""
	cdnBranch=""

	#  IN:2022-10-05-w3t.cfg:1.32.10.17020|931fc85d861c7ebb4dde1aa044f4ae9e|version-w3t-491204.bmime
	if (echo "$cdnString" | grep 'versions$' &>/dev/null); then
		# CDN branch not found, hack it in
		cdnString="${cdnString:0:-1}-w3cdnunknown"
		>&2 echo "   Did not find CDN branch :( adding a placeholder name: ${cdnString}"
	fi

	cdn_lineMatch="$(echo "$cdnString" | grep -oP '([\d.]+)\|[a-fA-F0-9]{32}\|version\-([^-]+)')"

	# OUT:1.32.10.17020|931fc85d861c7ebb4dde1aa044f4ae9e|version-w3t
	gameVer="$(echo "$cdn_lineMatch" | cut -d'|' -f 1)"
	cdnId="$(echo "$cdn_lineMatch" | cut -d'|' -f 2)"
	cdnBranch="$(echo "$cdn_lineMatch" | cut -d'|' -f 3)"
	cdnBranch="${cdnBranch##version-}"
fi

###

LAUNCH_WITH=""
if [[ -z "$windir" ]]; then
	command -v "wine" || echo "wine not found"
	# should exit due to set -e on next line
	LAUNCH_WITH="$(command -v "wine")"
fi

function echoerr() {
	>&2 echo "$@"
}

## ORIGINAL IN extract-from-mpq.sh
function mpqeditorSetExtractDir() {
	# Sets the path as Extraction dir in MPQEditor config

	# MPQEditor will create the folder automatically

	local extractPath="$1";
	local extractPathOsNative="$1"; # default is the passed path
	local mpqOrCascview="$2" # "mpqeditor" or "cascview"
	local iniName

	if [[ "$mpqOrCascview" == "cascview" ]]; then
		iniName="CascView.ini"
	elif [[ -z "$mpqOrCascview" ]] || [[ "$mpqOrCascview" = "mpqeditor" ]]; then
		# its ok
		iniName="MPQEditor.ini"
	else
		>&2 echo "mpqeditorSetExtractDir: unknown parameter value: $mpqOrCascview"
		exit 2
	fi

	if [[ -z "$extractPath" ]]; then
		echoerr "mpqeditorSetExtractDir: extractPath is empty!"
		exit 2
	fi
	if [[ ! -d "$extractPath" ]]; then
		echoerr "mpqeditorSetExtractDir: '$extractPath' is expected to be a directory!"
		exit 2
	fi

	local iniPath;
	if [[ "$(uname -o)" = "Cygwin" ]]; then
		iniPath="$(cygpath --unix "$APPDATA\\$iniName")"
		extractPathOsNative="$(cygpath --windows "$extractPath")"
	elif [[ "$(uname -s)" = "Linux" ]]; then
		iniPath="${HOME}/.wine/drive_c/users/$(whoami)/AppData/Roaming/${iniName}"
		# Forward slash to backslash (at least the one after C:\) or CascView complains
		# Z:\ is default Wine path for Linux root /
		extractPathOsNative='Z:\'"$extractPath"
	else
		echoerr "You are not running under Cygwin and I have no idea what the MPQ extraction path would be"
		echoerr "Please go to %appdata%/$iniName (or in MPQEditor options) and set the path to"
		echoerr "$extractPath"
		echoerr "Then just delete the if-else in the script file."
	fi

	if [[ -d "$iniPath" ]]; then
		echoerr "mpqeditorSetExtractDir: iniPath points to a directory, must be .ini: '$iniPath'"
		exit 2;

	elif [[ -f "$iniPath" ]]; then
		# TODO Security: Path must not contain |
		local pathBackslashEsc="${extractPathOsNative//\\/\\\\}"
		sed \
			-e 's|^ExtractPath=.*|ExtractPath='"${pathBackslashEsc}"'| ; s|ReadOnlyMode=false|ReadOnlyMode=true|' \
			"$iniPath" > "${iniPath}.new"

		mv "$iniPath" "${iniPath}.old"
		mv "${iniPath}.new" "$iniPath"
	else
		echoerr "Creating a new ini file for MPQEditor config!"
		echoerr "Path: '$iniPath'"
		printf "%s\n""ExtractPath=%s\n""ReadOnlyMode=%s\n" \
			"[Options]" "$extractPathOsNative" "true" \
			> "$iniPath"

	fi
}
## EOF

function pathLinuxToWineMaybe() {
	#TODO: BSD Support
	if [[ "$(uname -s)" = "Linux" ]]; then
		echo 'Z:\'"$1"
	else
		>&2 echo "not linux"
		echo "$1"
	fi

}

function main() {
	>&2 echo "-----"
	>&2 echo "$gameVer"
	>&2 echo "$cdnId"
	>&2 echo "$cdnBranch"
	>&2 echo "-----"
	local extractionSubdirPath="${extractionParentPath}/extract-${cdnBranch}-${gameVer}-${cdnId:0:7}"
	mkdir "$extractionSubdirPath" || true
	mpqeditorSetExtractDir "$extractionSubdirPath" "cascview"

	local extractionParentPathWine="$(pathLinuxToWineMaybe "$extractionParentPathWine")"
	local cascCachePathWine="$(pathLinuxToWineMaybe "$cascCachePath")"

	"$LAUNCH_WITH" "$cascViewPath" "/online" \
"${cascCachePathWine}*${cdnBranch}*${cdnGeo}*${cdnId}"
}
main "$@"
