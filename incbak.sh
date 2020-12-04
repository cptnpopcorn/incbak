#!/bin/bash

get_target_from_gendir() {
	local gendir="$1"
	local target

	for target in $gendir.*; do
		[ -e "$target" ] || target="$gendir.0"
		break
	done

	[ -e "$target" ] || mkdir "$target" || { echo "Could not create $target" 1>&2; exit 2; }
	echo "$target"
}

push_down() {
	local level="$1"
	local rev="$2"
	local target="$3"

	if [[ "$rev" -eq "1" && "$level" -le "$levels" ]]; then
		backup_level "$target" "$((level + 1))"
	else
		rm -r "$target" || { echo "Could not remove $target" 1>&2; exit 3; }
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
	mv "$ref" "$gendir.$nextrev"  || { echo "Could not move $ref to $gendir.$nextrev" 1>&2; exit 4; }

	push_down "$level" "$rev" "$target"

	return
}

shadow=".backup_sync"
exclude=".backup_exclude"

backup_root() {
	local ref="$1"
	local gendir="$dest.1"
	local target=$(get_target_from_gendir "$gendir")
	local rev="${target: -1}"
	local nextrev="$((1 - rev))"

	local excludefrom="/dev/null"
	[ -e "$ref/$exclude" ] && excludefrom="$ref/$exclude"
	echo "backup $ref to $gendir.$nextrev with hard-links to $target"
	rsync -aH --exclude-from="$excludefrom" --no-inc-recursive --delete --delete-after --link-dest="$target" "$ref/" "$gendir.$nextrev/" || { echo "Could not create primary backup from $ref to $gendir.$nextrev" 1>&2; exit 5; }

	# preserve current source and destination structure as hard-link copies, to identify moved files later
	rsync -a --exclude-from="$excludefrom" --delete --link-dest="$ref" --exclude="/$shadow" "$ref/" "$ref/$shadow" || { echo "Could not create shadow for $ref" 1>&2; exit 6; }
	rsync -a --exclude-from="$excludefrom" --delete --link-dest="$gendir.$nextrev" --exclude="/$shadow" "$gendir.$nextrev/" "$gendir.$nextrev/$shadow" || { echo "Could not create shadow for $gendir.$nextrev" 1>&2; exit 7; }

	push_down "0" "$rev" "$target"

	return
}

source="$1"
dest="$2"
levels="$3"

[ -d "$source" ] || { echo "Missing source" 1>&2; exit 1; }
[ -z "$dest" ] &&  { echo "Missing destination" 1>&2; exit 1; }
[ -z "$levels" ] && levels=8

source="$(realpath $source)"
dest="$(realpath $dest)"

backup_root "$source"
