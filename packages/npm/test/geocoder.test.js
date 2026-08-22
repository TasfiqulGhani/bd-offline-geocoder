import assert from "node:assert/strict";
import test from "node:test";
import { BANGLADESH_ONLY_MESSAGE, BdOfflineGeocoder } from "../src/index.js";

test("reverse from included data matches ADM4", () => {
  const geocoder = BdOfflineGeocoder.fromIncludedData();
  const result = geocoder.reverse({ latitude: 23.771, longitude: 90.355 });

  assert.equal(result.division, "Dhaka");
  assert.equal(result.district, "Dhaka");
  assert.equal(result.city, "Dhaka");
  assert.equal(result.unionWard, "Ward No-43");
  assert.equal(result.houseNumber, "৭৪৯");
  assert.ok(result.roadNumber === "০৮" || result.roadNumber === "8");
  assert.match(result.formatted, /Bangladesh/);
});

test("Dhanmondi includes locality and postal code", () => {
  const geocoder = BdOfflineGeocoder.fromIncludedData();
  const result = geocoder.reverse({ latitude: 23.74015, longitude: 90.38286 });

  assert.equal(result.houseNumber, "3");
  assert.equal(result.roadNumber, "3");
  assert.equal(result.areaVillage, "Dhanmondi");
  assert.equal(result.thanaUpazila, "Dhanmondi Thana");
  assert.equal(result.postalCode, "1209");
  assert.equal(result.unionWard, "Ward No-49");
  assert.equal(result.city, "Dhaka");
  assert.equal(result.toJSON().thana_upazila, "Dhanmondi Thana");
  assert.equal(
    result.formatted,
    "House 3, Road 3, Dhanmondi, Ward No-49, Dhanmondi Thana, Dhaka 1209, Bangladesh"
  );
});

test("fromIncludedData caches the parsed geocoder", () => {
  const first = BdOfflineGeocoder.fromIncludedData();
  const second = BdOfflineGeocoder.fromIncludedData();
  assert.equal(first, second);
});

test("invalid coordinates throw RangeError", () => {
  const geocoder = new BdOfflineGeocoder({ layers: [] });

  assert.throws(
    () => geocoder.reverse({ latitude: 100, longitude: 90 }),
    RangeError
  );
});

test("outside Bangladesh returns message", () => {
  const geocoder = BdOfflineGeocoder.fromIncludedData();
  const result = geocoder.reverse({ latitude: 27.7172, longitude: 85.3240 });

  assert.equal(result.found, false);
  assert.equal(result.message, BANGLADESH_ONLY_MESSAGE);
  assert.equal(result.formatted, BANGLADESH_ONLY_MESSAGE);
  assert.equal(result.toJSON().message, BANGLADESH_ONLY_MESSAGE);
});
