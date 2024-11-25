# Spatial 

This repository contains JSON geographic data and the scripts necessary for
converting cartographic boundary shapefiles to lightweight topojson files.

## To run

To build topojson files, run the following command inside this directory:

``` bash

$ > ./batch YYYY YYYY 
```

where the first `YYYY` is the starting year and the second `YYYY` is the ending
year of the files you wish to build. For example,

``` bash
$ > ./batch 2014 2023 
```

will build files for all years between 2014 and 2023, inclusive. The final
topojson files will be saved in the `data/json` directory.

## Boundaries

This script builds the following boundary files for each year selected:

- County
- Congressional district
- State

Each file contains boundaries for its level as well as those above it. 

- County levels:
  - `county`
  - `state`
  - `nation`
- Congressional district levels:
  - `cdistrict`
  - `state`
  - `nation`
- State levels:
  - `state`
  - `nation`

