import { BdOfflineGeocoder } from "../../packages/npm/src/index.js";

const geocoder = BdOfflineGeocoder.fromIncludedData();
const result = geocoder.reverse({ latitude: 23.74015, longitude: 90.38286 });

console.log(result.formatted);
console.log(JSON.stringify(result.toJSON(), null, 2));
