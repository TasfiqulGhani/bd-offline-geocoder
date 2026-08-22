# Bangladesh postcodes

`unique_area_postcodes.json` is a derived lookup of Bangladesh Post Office
thana names that have **exactly one** postcode in that district.

- Source names: community compilation of official Bangladesh Post codes
  ([tlstanjim/bangladesh-postal-codes-database](https://github.com/tlstanjim/bangladesh-postal-codes-database))
- Facts (4-digit codes) are public
- Ambiguous thanas (Gulshan, Mohammadpur, Savar, …) are omitted on purpose

The geocoder only fills `postal_code` when the matched area name is unique
for that district. It never invents a house-level ZIP.
