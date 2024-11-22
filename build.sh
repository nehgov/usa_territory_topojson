#!/usr/bin/env bash

#################################################################################
#
# [ PROJ ] Spatial
# [ FILE ] bash
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

# year
yr=2023

# census tiger file base url
base_url=https://www2.census.gov/geo/tiger/GENZ${yr}/shp

# inputs
c_stub=cb_${yr}_us_county_5m
c_data_zip=${SHP_DIR}/${c_stub}.zip
c_data_shp=${SHP_DIR}/${c_stub}.shp
c_data_dbf=${SHP_DIR}/${c_stub}.dbf
s_stub=cb_${yr}_us_state_5m
s_data_zip=${SHP_DIR}/${s_stub}.zip
s_data_shp=${SHP_DIR}/${s_stub}.shp
s_data_dbf=${SHP_DIR}/${s_stub}.dbf

# outputs
c_json=county.json
s_json=state.json

# --- download -----------------------------------

rm ${GEO_DIR}/*.json
mkdir -p ${GEO_DIR} ${SHP_DIR}

# county
if [ ! -f ${c_data_shp} ]; then
	curl -o ${c_data_zip} ${base_url}/${c_stub}.zip;
	unzip -od ${SHP_DIR} ${SHP_DIR}/${c_stub}.zip ${c_stub}.shp ${c_stub}.dbf;
	chmod a-x ${SHP_DIR}/${c_stub}.*;
fi
# state
if [ ! -f ${s_data_shp} ]; then
	curl -o ${s_data_zip} ${base_url}/${s_stub}.zip;
	unzip -od ${SHP_DIR} ${SHP_DIR}/${s_stub}.zip ${s_stub}.shp ${s_stub}.dbf;
	chmod a-x ${SHP_DIR}/${s_stub}.*;
fi

# --- settings -----------------------------------

# some (temporary?) weirdness with npm, so this stops a bunch of noise in the
# terminal; can comment out to check if things go awry
export NODE_NO_WARNINGS=1

# --- build --------------------------------------

# counties
npx shp2json --encoding utf-8 -n ${SHP_DIR}/${c_stub}.shp \
	| npx ndjson-filter '!/000$/.test(d.properties.GEOID)' \
	| npx ndjson-map '(d.id = d.properties.GEOID, delete d.properties, d)' \
	> ${GEO_DIR}/counties_tmp.json

npx geo2topo -q 1e5 -n counties=${GEO_DIR}/counties_tmp.json \
| npx toposimplify -f -s 1e-7 \
| npx topomerge states=counties -k 'd.id.slice(0,2)' \
| npx topomerge nation=states \
| node ${SCR_DIR}/properties.js \
> ${GEO_DIR}/${c_json}

# states
npx shp2json --encoding utf-8 -n ${SHP_DIR}/${s_stub}.shp \
	| npx ndjson-filter '!/000$/.test(d.properties.GEOID)' \
	| npx ndjson-map '(d.id = d.properties.GEOID, d.properties = {name: d.properties.NAME}, d)' \
	> ${GEO_DIR}/states_tmp.json

npx geo2topo -q 1e5 -n states=${GEO_DIR}/states_tmp.json \
| npx toposimplify -f -s 1e-7 \
| npx topomerge nation=states \
> ${GEO_DIR}/${s_json}

## --- clean up ----------------------------------

rm ${GEO_DIR}/*_tmp.json

# ------------------------------------------------------------------------------
# end makefile
################################################################################
