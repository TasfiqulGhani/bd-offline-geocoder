export type LayerTypeValue =
  | "division"
  | "district"
  | "upazila"
  | "union"
  | "locality"
  | "custom";

export const LayerType: Readonly<{
  DIVISION: "division";
  DISTRICT: "district";
  UPAZILA: "upazila";
  UNION: "union";
  LOCALITY: "locality";
  CUSTOM: "custom";
}>;

export const DEFAULT_NAME_KEYS: readonly string[];

export const BANGLADESH_ONLY_MESSAGE: string;

export const BoundaryDataPaths: Readonly<{
  divisions: string;
  districts: string;
  upazilas: string;
  unions: string;
}>;

export class AddressResult {
  country: string;
  houseNumber: string | null;
  roadNumber: string | null;
  roadName: string | null;
  areaVillage: string | null;
  unionWard: string | null;
  thanaUpazila: string | null;
  district: string | null;
  division: string | null;
  postalCode: string | null;
  city: string | null;
  message: string | null;
  matchedLayers: Record<string, Record<string, unknown>>;
  readonly found: boolean;
  readonly formatted: string;
  toJSON(): Record<string, unknown>;
}

export class BoundaryLayer {
  id: string;
  type: LayerTypeValue;
  features: unknown[];
  namePropertyCandidates: readonly string[];
  constructor(options: {
    id: string;
    type: LayerTypeValue;
    features: unknown[];
    namePropertyCandidates?: readonly string[];
  });
  static fromFile(path: string, options: {
    id: string;
    type: LayerTypeValue;
    namePropertyCandidates?: readonly string[];
  }): BoundaryLayer;
  static fromGeoJSON(geojson: Record<string, unknown>, options: {
    id: string;
    type: LayerTypeValue;
    namePropertyCandidates?: readonly string[];
  }): BoundaryLayer;
  match(latitude: number, longitude: number): unknown | null;
  displayNameFor(feature: { properties: Record<string, unknown> }): string | null;
}

export class BdOfflineGeocoder {
  layers: readonly BoundaryLayer[];
  countryName: string;
  constructor(options: { layers: BoundaryLayer[]; countryName?: string });
  static fromIncludedData(options?: { reload?: boolean }): BdOfflineGeocoder;
  reverse(options: { latitude: number; longitude: number }): AddressResult;
}
