#!/bin/bash
# Pull all current MFEK modules! Latest version @ https://github.com/MFEK/docs/

MODULES=("glif" "stroke" "metadata" "init" "about")

for m in ${MODULES[@]}; do
	if [ ! -d MFEK"$m" ]; then
		git clone https://github.com/MFEK/"$m" MFEK"$m"
	else
		cd MFEK"$m";
		git pull --ff-only
		cd ..
	fi
done
