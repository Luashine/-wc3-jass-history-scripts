#!/usr/bin/env bash

# Usage:
# ./script <path to ribbit/ngdp data of the game you want> > version-list.txt

# Syntax:
# ./script <path> [path2] [path3...]

# Example:
# ./show-unique-builds-from-ribbit-data.sh './Warcraft-ngdp-repo' > ngdp-repo-20221013-AllWar3.cfg


function extractBuildConfigs() {
	local ribbitFolder="$1"
	
	local prevBuildConfig=""
	
	# https://stackoverflow.com/questions/8677546/reading-null-delimited-strings-through-a-bash-loop
	while IFS= read -r -d $'\0' file; do
		# Arbitrary operations on "$file" here
		local fileName="$(basename "$file")"

		#>&2 echo "File: '$file'"
		
		# header _could_ be dynamic
		local buildDefinition="$(grep -F 'Region!' "$file" --after-context 2 | tail -n 1)"
		#echo "${fileName}: $buildDefinition"
		
		local buildConfig="$(echo "$buildDefinition" | cut -d '|' -f 2)"
		# dont print duplicates, but files are out of order anyway
		if [[ "$buildConfig" != "$prevBuildConfig" ]]; then
			local versionName="$(echo "$buildDefinition" | cut -d '|' -f 6)"
			
			# 1.32.2.14722|fd283a3545d954fa86e36a1e464fd226|version-w3-152708.bmime
			echo "${versionName}|${buildConfig}|${fileName}"
		fi;
		
		prevBuildConfig="$buildConfig"
		
	done < <(find "$ribbitFolder" -iname 'version*' -type f -print0)

	unset IFS;
}

function uniqueBuildConfigs() {
	local prevBuildConfig=""
	
	for ribbitFolder in "$@"; do
		>&2 echo "Processing folder '$ribbitFolder'"

		# sort by buildconfig hash then dedupe here
		while read -r configLine; do
			local buildConfig="$(echo "$configLine" | cut -d '|' -f 2)"

			if [[ "$buildConfig" != "$prevBuildConfig" ]]; then
				echo "$configLine"
			fi

			prevBuildConfig="$buildConfig"

		done < <(extractBuildConfigs "$ribbitFolder" | sort -t '|' -k 2)

	done
}

>&2 echo "Please wait! The data is being extracted, sorted, then deduplicated"

uniqueBuildConfigs "$@" | sort --version-sort

