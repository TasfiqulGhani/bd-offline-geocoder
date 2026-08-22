from bd_offline_geocoder import BdOfflineGeocoder


def main() -> None:
    geocoder = BdOfflineGeocoder.from_included_data()
    result = geocoder.reverse(latitude=23.74015, longitude=90.38286)

    print(result.formatted)
    print(result.to_dict())


if __name__ == "__main__":
    main()
