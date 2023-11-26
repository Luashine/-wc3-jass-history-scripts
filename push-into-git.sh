#!/usr/bin/env bash

# USAGE:

# sh push-into-git.sh [--ignore-count] /path/to/jass-history-git/

# This will record each child dir of $historicDir as a separate commit and tag.

# The list of folders is specified in $versionList, should be sorted to have proper diffs.

# --ignore-count will ignore a mismatch between folders present and lines recorded in sorted list

set -e

ignoreCountMismatch="n"
if [[ "$1" = "--ignore-count" ]]; then
	ignoreCountMismatch="y"
	shift;
fi

gitDir="$1"
historicDir="war3extract"
versionedDir="timeline"
# must have paths relative to historicDir
# like ROC-v1.01-ru, without slashes or dots
versionList="version-list-sorted.txt"

echoerr() {
	>&2 echo "$@"
}

if [[ -z "$gitDir" ]]; then
	echoerr "You must specify the target git folder as first arg"
	exit 2
fi

main() {
	cd "$gitDir"
	echoerr "Checking for uncommited changes (repo must be clean)..."
	git status; # ensure its a git repo, else non-zero exit
	git diff --name-only --quiet --exit-code
	# non-zero exit if unstaged changes
	# i.e. aborts with set -e
	if [[ ! -z "$(git status --porcelain)" ]]; then
		echoerr "There are outstanding changes or untracked files in repository!"
		echoerr "Remove them or otherwise clean the repo folder!"
		exit 5
	fi
	
	local listEntryCount="$(wc -l <"$versionList")"
	local historicEntryCount="$(find "$historicDir" -maxdepth 1 -mindepth 1 -type d | wc -l)"
	
	if [[ ! "$listEntryCount" -eq "$historicEntryCount" ]]; then
		if [[ "$ignoreCountMismatch" != "y" ]]; then
			echoerr "Filtered version list mismatched entry count compared to folder on disk:"
			>&2 printf "%d vs %d, expected equal\n" "$listEntryCount"  "$historicEntryCount"
			exit 4
		fi
	fi
	
	while read -u 5 ver; do
		echoerr "Starting version: '$ver'"
		
		local verPath="$historicDir/$ver"
		if [[ ! -d "$verPath" ]]; then
			echoerr "$verPath not found here"
			pwd;
			exit 3
		fi
		
		rm -rf -- "./${versionedDir:-failsafe_rm-rf}" || true;
		# no mkdir, so cp renames the copied directory
		#mkdir -- "./$versionedDir" || true;
		
		echoerr "Starting copy: $verPath to $versionedDir"
		cp --recursive -- "$verPath" "$versionedDir"
		
		git add --all .
		
		set +e
		git diff --cached --name-only --quiet --exit-code
		local hasChanges=$?
		set -e
		local isEmptyText=""
		if [[ $hasChanges -eq 0 ]]; then
			isEmptyText="[EMPTY] "
		fi
		
		echoerr "Commiting: $ver"
		git commit --allow-empty -m "${isEmptyText}version: $ver"
		git tag --force "$ver"
		
		#echoerr "Press ENTER to continue"
		#read;
		
	done 5< "$versionList"
}
main;
