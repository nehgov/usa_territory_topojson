# Spatial 

This repository contains JSON geographic data and the scripts necessary for
converting cartographic boundary shapefiles to lightweight topojson files.

## To run

To build all topojson files, run the following command inside the `scripts/bash`
directory:

``` bash
$ > cd ./scripts/bash
$ scripts/bash> ./batch -s YYYY -e YYYY -r 500k, 5m, 20m 
```
where 

``` bash
[-s]       Survey year start
[-e]       Survey year end (if blank, assumed same as start)
[-r]       Resolution: 500k, 5m, 20m
```

For example,

``` bash
$ > ./batch -s 2014 -e 2023 -r 5m 
```

will build 5m resolution files for all years between 2014 and 2023, inclusive.
You can build all resolutions by separating each resolution after the `-r` flag
with commas:

``` bash
$ > ./batch -s 2020 -e 2021 -r 500k,5m,20m
```

If you leave out the `-e` flag, the script will build only the year after the
`-s` flag. In all cases, final topojson files will be saved in the `data/json`
directory.

## Boundaries

This script builds the following boundary files for each year selected:

- State
- County
- Congressional district


Each file contains boundaries for its level as well as those above it. 

- State levels:
  - `state`
  - `nation`
- County levels:
  - `county`
  - `state`
  - `nation`
- Congressional district levels:
  - `cdistrict`
  - `state`
  - `nation`
  
## Checking maps

If you would like to visualize the maps, start a local server in the root
directory (see: npm local-web-server) and visit localhost page. From there, you
can select the various maps via a dropdown menu.

``` bash
$ > npm install local-web-server
$ > npx ws
```
Paste `http://127.0.0.1:8000` in your browser.

![Check maps locally](./img/check_map.png)
