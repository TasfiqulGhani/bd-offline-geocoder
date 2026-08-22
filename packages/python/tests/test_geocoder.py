import math

from bd_offline_geocoder import BANGLADESH_ONLY_MESSAGE, BdOfflineGeocoder


def test_reverse_from_included_data_matches_adm4():
    geocoder = BdOfflineGeocoder.from_included_data()

    result = geocoder.reverse(latitude=23.771, longitude=90.355)

    assert result.division == "Dhaka"
    assert result.district == "Dhaka"
    assert result.city == "Dhaka"
    assert result.union_ward == "Ward No-43"
    assert result.house_number == "৭৪৯"
    assert result.road_number in {"০৮", "8"}
    assert "Bangladesh" in result.formatted


def test_dhanmondi_includes_locality_and_postal_code():
    geocoder = BdOfflineGeocoder.from_included_data()

    result = geocoder.reverse(latitude=23.74015, longitude=90.38286)

    assert result.house_number == "3"
    assert result.road_number == "3"
    assert result.road_name in {None, ""}
    assert result.area_village == "Dhanmondi"
    assert result.thana_upazila == "Dhanmondi Thana"
    assert result.postal_code == "1209"
    assert result.union_ward == "Ward No-49"
    assert result.city == "Dhaka"
    assert result.to_dict()["thana_upazila"] == "Dhanmondi Thana"
    assert (
        result.formatted
        == "House 3, Road 3, Dhanmondi, Ward No-49, Dhanmondi Thana, Dhaka 1209, Bangladesh"
    )


def test_from_included_data_is_cached():
    first = BdOfflineGeocoder.from_included_data()
    second = BdOfflineGeocoder.from_included_data()
    assert first is second


def test_invalid_coordinates_raise_value_error():
    geocoder = BdOfflineGeocoder([])

    try:
        geocoder.reverse(latitude=100, longitude=90)
    except ValueError:
        pass
    else:
        raise AssertionError("expected ValueError")

    try:
        geocoder.reverse(latitude=math.nan, longitude=90)
    except ValueError:
        pass
    else:
        raise AssertionError("expected ValueError for NaN")


def test_outside_bangladesh_returns_message():
    geocoder = BdOfflineGeocoder.from_included_data()

    result = geocoder.reverse(latitude=27.7172, longitude=85.3240)

    assert result.found is False
    assert result.message == BANGLADESH_ONLY_MESSAGE
    assert result.formatted == BANGLADESH_ONLY_MESSAGE
    assert result.to_dict()["message"] == result.message
