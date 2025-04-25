#!/bin/sh
#title           :prepare_ecfp4.sh
#description     :Calculate ECFP4 molecular descriptor
#author          :Carlos Vigil Vásquez
#date            :20250409
#version         :20250409a
#notes           :Requires obabel
#copyright       :Copyright (C) 2022 Carlos Vigil Vásquez (carlos.vigil.v@gmail.com).
#license         :Permission to copy and modify is granted under the MIT license


SMILES=$1
ECFP4=$2

echo "Calculating OpenBabel's ECFP4 fingerprint for $1"

# Calculate and clean-up descriptor
obabel "$SMILES" -ofpt -O "$(basename "$ECFP4")" -xh -xfECFP4

# Retrieve compound names
grep '^>' "$(basename "$ECFP4")" |\
	sed "s/^>\(\w\+\).*/\"\1\"/g" > "$(basename "$ECFP4")_names"

# Convert hex to binary
grep -v 'Possible superstructure of' "$(basename "$ECFP4")" |\
	grep -v '>' | paste -d '\0'  - - - - - - - - - - - - - - - - - - - - - -  |\
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
	sed 's/[[:space:]]*$//' > "$(basename "$ECFP4")_binary"
paste -d" " "$(basename "$ECFP4")_names" "$(basename "$ECFP4")_binary" > "$ECFP4"
