const shapefile = require("shapefile");
const argv = process.argv;
const state_shp_file = argv[2];

Promise.all([
  parseInput(),
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

function output([topology, states]) {
  states = new Map(states.features.map(d => [d.properties.GEOID, d.properties]));
  for (const state of topology.objects.states.geometries) {
    state.properties = {
      name: states.get(state.id).NAME
    };
  }
  process.stdout.write(JSON.stringify(topology));
  process.stdout.write("\n");
}
