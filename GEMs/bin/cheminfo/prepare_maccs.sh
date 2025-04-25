#!/bin/sh
#title           :prepare_maccs.sh
#description     :Calculate MACCS molecular descriptor
#author          :Carlos Vigil Vásquez
#date            :20220829
#version         :20220829a
#notes           :Requires obabel
#copyright       :Copyright (C) 2022 Carlos Vigil Vásquez (cvigil2@uc.cl).
#license         :Permission to copy and modify is granted under the MIT license

SMILES=$1
MACCS="$(echo "$SMILES" | sed s/smi/maccs.txt/)"

echo "Calculating OpenBabel's MACCS fingerprint for $1"

# Calculate and clean-up descriptor
obabel -ismi "$SMILES" -ofpt -O "/tmp/$(basename "$MACCS")" -xh -xfMACCS

# Retrieve compound names
grep '^>' "/tmp/$(basename "$MACCS")" |\
	sed "s/^>\(\w\+\).*/\"\1\"/g" > "/tmp/$(basename "$MACCS")_names"

# Convert hex to binary
grep -v 'Possible superstructure of' "/tmp/$(basename "$MACCS")" |\
	grep -v '>' | paste -d '\0'  - - |\
	sed s/' '//g | tr "[a-z]" "[A-Z]" | \
	sed s/0/0000/g | \
	sed s/1/0001/g | \
	sed s/2/0010/g | \
	sed s/3/0011/g | \
	sed s/4/0100/g | \
	sed s/5/0101/g | \
	sed s/6/0110/g | \
	sed s/7/0111/g | \
	sed s/8/1000/g | \
	sed s/9/1001/g | \
	sed s/A/1010/g | \
	sed s/B/1011/g | \
	sed s/C/1100/g | \
	sed s/D/1101/g | \
	sed s/E/1110/g | \
	sed s/F/1111/g | \
	sed 's/./& /g' | \
	sed 's/[[:space:]]*$//' > "/tmp/$(basename "$MACCS")_binary"
paste -d" " "/tmp/$(basename "$MACCS")_names" "/tmp/$(basename "$MACCS")_binary" > "$MACCS"
