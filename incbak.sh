#!/bin/bash

backup_level() {
	local ref="$1"
	local level="$2"
	local gen="$((1 << level))"
	local gendir="$dest.$gen"

	for target in $gendir.*; do
		[ -e "$target" ] || target="$gendir.0"
		break
	done

	[ -e "$target" ] || mkdir "$target" || exit
	local rev="${target: -1}"
	local nextrev="$((1 - rev))"
	
	if [ "$level" -eq "0" ]; then
		echo "backup $ref to $gendir.$nextrev with hard-links to $target"
		rsync -a --delete --link-dest="$target" "$ref/" "$gendir.$nextrev/" || exit
	else
		echo "move $ref down to $gendir.$nextrev"
		mv "$ref" "$gendir.$nextrev"  || exit
	fi

	if [[ "$rev" -eq "1" && "$level" -le "$levels" ]]; then
		backup_level "$target" "$((level + 1))"
	else
		rm -r "$target" || exit
	fi				

	return
}

source="$(realpath $1)"
dest="$(realpath $2)"
levels="$3"

if [ ! -d "$source" ]; then echo "missing source" 1>&2; exit 1; fi
if [ -z "$dest" ]; then echo "missing destination" 1>&2; exit 1; fi
[ -z "$levels" ] && levels=8

backup_level "$source" 0
