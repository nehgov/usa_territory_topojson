# USA states + territories from SHP to TOPOJSON 

This repository contains JSON geographic data and the scripts necessary for
converting cartographic boundary shapefiles to lightweight topojson files.

## Dependencies

In order to build the maps, you will need the following Javascript libraries
installed on your machine:

- shapefile
- ndjson-cli
- topojson-server
- topojson-simplify
- topojson-client
- d3-geo-projection
- geo-albers-usa-territories

You can get them each through npm: `npm install <package>`

## To build maps

To build all topojson files, run the following command inside the `scripts/bash`
directory:

``` bash
$ > cd ./scripts/bash
$ > ./batch -s YYYY -e YYYY -r 500k,5m,20m 
```
where 

``` bash
[-s]       Survey year start
[-e]       Survey year end (if blank, assumed same as start)
[-r]       Resolution: 500k, 5m, 20m
[-p]       Project (AlbersUsaTerritories)
```

For example,

``` bash
$ > ./batch -s 2014 -e 2023 -r 5m 
```

will build unprojected 5m resolution files for all years between 2014 and 2023,
inclusive. You can build all resolutions by separating each resolution after the
`-r` flag with commas:

``` bash
$ > ./batch -s 2020 -e 2021 -r 500k,5m,20m
```

If you leave out the `-e` flag, the script will build only the year after the
`-s` flag.

If you wish to pre-project the file using the [AlbersUsaTerritories
projection](https://github.com/stamen/geo-albers-usa-territories),
which can save the processing required to make projections at runtime (speed
up), then add the `-p` flag:

``` bash
$ > ./batch -s 2020 -e 2021 -r 5m -p
```

In all cases, final topojson files will be saved in either the
`data/json/unprojected` or `data/json/projected` directory as determined by the
`-p` flag.

# Boundaries

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
  
# Projections

To project the topojson data files so that non-contiguous states and territories
are moved for easier mapping, you will need to use the json scripts located in `assets/js`:

- `d3.v7.min.js`
- `topojson.min.js`
- `geoalbersuster.js`

The first two scripts are general libraries for working with D3 and topojson
files. The third file contains the scripts necessary for projecting the
unprojected maps with the key function:

``` javascript
const projection = geoAlbersUsaTerritories.geoAlbersUsaTerritories()
  .scale(1280)
  .translate([width / 2, height / 2]);
const path = d3.geoPath().projection(projection);
```
  
## Visualizing maps

If you would like to visualize the projected maps, start a local server in the
root directory (see: npm local-web-server) and visit localhost page. From there,
you can select the various maps via a drop down menu.

``` bash
$ > npm install local-web-server
$ > npx ws
```
Paste `http://127.0.0.1:8000` in your browser.

![View maps locally](./img/check_map.png)

## Using maps in other projects

The script section in `index.html` can be modified / reused in order to use
these maps in other projects.

# Acknowledgments

- [Projection](https://github.com/stamen/geo-albers-usa-territories)
- [Command line cartography](https://medium.com/@mbostock/command-line-cartography-part-1-897aa8f8ca2c)

