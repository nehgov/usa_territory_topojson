#!/usr/bin/env bash

#################################################################################
#
# [ PROJ ] Spatial
# [ FILE ] build
# [ AUTH ] Benjamin Skinner; bskinner@neh.gov
# [ INIT ] 22 November 2024
#
################################################################################

# --- directories --------------------------------

DAT_DIR=data
GEO_DIR=${DAT_DIR}/json
SHP_DIR=${DAT_DIR}/shp
SCR_DIR=js

# --- variables ----------------------------------

# year (call from command line argument:
# e.g.,
# $> ./build.sh 2023
yr=$1

# census tiger file base url (using cartographic boundary files)
# https://www.census.gov/geographies/mapping-files/time-series/geo/cartographic-boundary.html
base_url=https://www2.census.gov/geo/tiger/GENZ${yr}/shp

# inputs
#
# ct := county
# st := state
# cd := congressional district
#
# NB: congressional districts are labeled with their congressional session
# numbers, which means we need if/else statements to make sure we get the right
# file name when using the calendar year
ct_stub=cb_${yr}_us_county_5m
st_stub=cb_${yr}_us_state_5m
if [[ ${yr} -eq 2023 || ${yr} -eq 2022 ]]; then
	cd_stub=cb_${yr}_us_cd118_5m
elif [[ ${yr} -eq 2021 || ${yr} -eq 2020 || ${yr} -eq 2019 || ${yr} -eq 2018 ]]; then
	cd_stub=cb_${yr}_us_cd116_5m
elif [[ ${yr} -eq 2017 || ${yr} -eq 2016 ]]; then
	cd_stub=cb_${yr}_us_cd115_5m
elif [[ ${yr} -eq 2015 || ${yr} -eq 2014 ]]; then
	cd_stub=cb_${yr}_us_cd114_5m
fi

# outputs
#
# name of geographic level plus year: county_2023.json
#
# NB: the congressional districts will be redundant for multiple years, which
# may be accounted in later code to reduce transferring multiple versions of the
# same file (i.e., save bandwidth), but it's still good to have a file for each
# year for consistency
ct_json=county_${yr}.json
st_json=state_${yr}.json
cd_json=cdistrict_${yr}.json

# --- clean up -----------------------------------

# javascript functions in a bash environment don't always allow overwriting
# existing files, so we preemptively delete existing final files using -f flag
# to silence a warning if the file doesn't exist; we also create the shapefile
# and json subdirectories in the /data directory if they don't exist

echo "  - Removing old topojson files"
rm -f ${GEO_DIR}/*_${yr}.json
mkdir -p ${GEO_DIR} ${SHP_DIR}

# --- download -----------------------------------

# if the geographic level + year (e.g., county_2023) doesn't exist in the
# shapefile subdirectory:
#
# 1) the zip file will be downloaded from the Census website
# 2) the *.shp and *.dbf files will be unpacked from the zip directory
# 3) remove the executable permissions on the files

# county
if [ ! -f ${SHP_DIR}/${ct_stub}.shp ]; then
	echo "  - Downloading COUNTY shapefile"
	curl -s -o ${SHP_DIR}/${ct_stub}.zip ${base_url}/${ct_stub}.zip;
	echo "    - Unzipping COUNTY shapefile"
	unzip -q -od ${SHP_DIR} ${SHP_DIR}/${ct_stub}.zip ${ct_stub}.shp ${ct_stub}.dbf;
	echo "    - Changing COUNTY shapefile file permissions"
	chmod a-x ${SHP_DIR}/${ct_stub}.*;
fi
# congressional district
if [ ! -f ${SHP_DIR}/${cd_stub}.shp ]; then
	echo "  - Downloading CONGRESSIONAL DISTRICT shapefile"
	curl -s -o ${SHP_DIR}/${cd_stub}.zip ${base_url}/${cd_stub}.zip;
	echo "    - Unzipping CONGRESSIONAL DISTRICT shapefile"
	unzip -q -od ${SHP_DIR} ${SHP_DIR}/${cd_stub}.zip ${cd_stub}.shp ${cd_stub}.dbf;
	echo "    - Changing CONGRESSIONAL DISTRICT shapefile file permissions"
	chmod a-x ${SHP_DIR}/${cd_stub}.*;
fi
# state
if [ ! -f ${SHP_DIR}/${st_stub}.shp ]; then
	echo "  - Downloading STATE shapefile"
	curl -s -o ${SHP_DIR}/${st_stub}.zip ${base_url}/${st_stub}.zip;
	echo "    - Unzipping STATE shapefile"
	unzip -q -od ${SHP_DIR} ${SHP_DIR}/${st_stub}.zip ${st_stub}.shp ${st_stub}.dbf;
	echo "    - Changing STATE shapefile file permissions"
	chmod a-x ${SHP_DIR}/${st_stub}.*;
fi

# --- settings -----------------------------------

# some (temporary?) weirdness with npm, so this stops a bunch of noise in the
# terminal; can comment out to check if things go awry
export NODE_NO_WARNINGS=1

# --- build --------------------------------------

# SHP files will be converted to TOPOJSON in two steps using a suite of node
# commands (package):
#
# - shp2json (shapefile)
# - ndjson-filter (ndjson-cli)
# - ndjson-map (ndjson-cli)
# - geo2topo (topojson-server)
# - toposimplify (topojson-simplify)
# - topomerge (topojson-client)
#
# these packages can be downloaded using
#
# $> npm install < package >
#
# to call the command, the initial command npx should be used in front, e.g.,
#
# $> npx shp2json ...
#
# PROCESS:
#
# 1) shp2json converts the shapefile to a newline geojson file, encoding to UTF-8
# 2) filter to keep rows with the GEOID property
# 3) move the geoid from properties to its own id and delete properties to reduce size
# 4) save as *_tmp.json file (still geojson)
# 5) convert to topojson file, reducing via quantization (bigger number means
#    larger file size but more detail), and naming smallest geographic unit
# 6) simplify further
# 7) merge up to next level (counties --> states) using portions of id as
#    appropriate; repeat for counties and congressional districts to nation
# 8) for counties/congressional districts, add (county) state names back to
#    properties
# 9) write topojson file

# counties
echo "  - Converting COUNTY shapefile to topojson"
npx shp2json --encoding utf-8 -n ${SHP_DIR}/${ct_stub}.shp \
	| npx ndjson-filter '!/000$/.test(d.properties.GEOID)' \
	| npx ndjson-map '(d.id = d.properties.GEOID, delete d.properties, d)' \
	> ${GEO_DIR}/county_tmp.json

npx geo2topo -q 1e5 -n counties=${GEO_DIR}/county_tmp.json \
	| npx toposimplify -f -s 1e-7 \
	| npx topomerge states=counties -k 'd.id.slice(0,2)' \
	| npx topomerge nation=states \
	| node ${SCR_DIR}/county_properties.js ${SHP_DIR}/${ct_stub}.shp ${SHP_DIR}/${st_stub}.shp \
	> ${GEO_DIR}/${ct_json}

# congressional districts
echo "  - Converting CONGRESSIONAL DISTRICT shapefile to topojson"
npx shp2json --encoding utf-8 -n ${SHP_DIR}/${cd_stub}.shp \
	| npx ndjson-filter '!/000$/.test(d.properties.GEOID)' \
	| npx ndjson-map '(d.id = d.properties.GEOID, delete d.properties, d)' \
	> ${GEO_DIR}/cdistrict_tmp.json

npx geo2topo -q 1e5 -n cdistricts=${GEO_DIR}/cdistrict_tmp.json \
	| npx toposimplify -f -s 1e-7 \
	| npx topomerge states=cdistricts -k 'd.id.slice(0,2)' \
	| npx topomerge nation=states \
	| node ${SCR_DIR}/condist_properties.js ${SHP_DIR}/${st_stub}.shp \
	> ${GEO_DIR}/${cd_json}

# states
echo "  - Converting STATE shapefile to topojson"
npx shp2json --encoding utf-8 -n ${SHP_DIR}/${st_stub}.shp \
	| npx ndjson-filter '!/000$/.test(d.properties.GEOID)' \
	| npx ndjson-map '(d.id = d.properties.GEOID, d.properties = {name: d.properties.NAME}, d)' \
	> ${GEO_DIR}/state_tmp.json

npx geo2topo -q 1e5 -n states=${GEO_DIR}/state_tmp.json \
	| npx toposimplify -f -s 1e-7 \
	| npx topomerge nation=states \
	> ${GEO_DIR}/${st_json}

## --- clean up ----------------------------------

# remove temporary files

echo "  - Cleaning up temporary files"
rm ${GEO_DIR}/*_tmp.json

# ------------------------------------------------------------------------------
# end build
################################################################################
