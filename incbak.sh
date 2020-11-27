#!/bin/bash

get_target_from_gendir() {
	local gendir="$1"
	local target

	for target in $gendir.*; do
		[ -e "$target" ] || target="$gendir.0"
		break
	done

	[ -e "$target" ] || mkdir "$target" || exit
	echo "$target"
}

push_down() {
	local level="$1"
	local rev="$2"
	local target="$3"

	if [[ "$rev" -eq "1" && "$level" -le "$levels" ]]; then
		backup_level "$target" "$((level + 1))"
	else
		rm -r "$target" || exit
	fi

	return
}

backup_level() {
	local ref="$1"
	local level="$2"
	local gendir="$dest.$((1 << level))"
	local target=$(get_target_from_gendir "$gendir")
	local rev="${target: -1}"
	local nextrev="$((1 - rev))"

	echo "move $ref down to $gendir.$nextrev"
	mv "$ref" "$gendir.$nextrev"  || exit

	push_down "$level" "$rev" "$target"

	return
}

backup_root() {
	local ref="$1"
	local gendir="$dest.1"
	local target=$(get_target_from_gendir "$gendir")
	local rev="${target: -1}"
	local nextrev="$((1 - rev))"

	echo "backup $ref to $gendir.$nextrev with hard-links to $target"
	rsync -a --delete --link-dest="$target" "$ref/" "$gendir.$nextrev/" || exit

	push_down "0" "$rev" "$target"

	return
}

source="$1"
dest="$2"
levels="$3"

if [ ! -d "$source" ]; then echo "missing source" 1>&2; exit 1; fi
if [ -z "$dest" ]; then echo "missing destination" 1>&2; exit 1; fi
[ -z "$levels" ] && levels=8

source="$(realpath $source)"
dest="$(realpath $dest)"


backup_root "$source"
