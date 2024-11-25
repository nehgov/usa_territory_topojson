const shapefile = require("shapefile");
const argv = process.argv;
const county_shp_file = argv[2];
const state_shp_file = argv[3];

Promise.all([
  parseInput(),
  shapefile.read(county_shp_file, undefined, {encoding: "utf-8"}),
  shapefile.read(state_shp_file, undefined, {encoding: "utf-8"})
]).then(output);

function parseInput() {
  return new Promise((resolve, reject) => {
    const chunks = [];
    process.stdin
        .on("data", chunk => chunks.push(chunk))
        .on("end", () => {
          try { resolve(JSON.parse(chunks.join(""))); }
          catch (error) { reject(error); }
        })
        .setEncoding("utf8");
  });
}

function output([topology, counties, states]) {
  counties = new Map(counties.features.map(d => [d.properties.GEOID, d.properties]));
  states = new Map(states.features.map(d => [d.properties.GEOID, d.properties]));
  for (const county of topology.objects.counties.geometries) {
    county.properties = {
      name: counties.get(county.id).NAME
    };
  }
  for (const state of topology.objects.states.geometries) {
    state.properties = {
      name: states.get(state.id).NAME
    };
  }
  process.stdout.write(JSON.stringify(topology));
  process.stdout.write("\n");
}
