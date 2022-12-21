const L = require('leaflet/dist/leaflet');
const LGH = require('leaflet-gesture-handling/dist/leaflet-gesture-handling');

const CENTER_OF_GERMANY = [51.3127114, 9.4797461];
const DEFAULT_ZOOM_LEVEL = 6;
const ICON = L.icon({
  iconUrl: '/marker.svg',
  iconSize: [30, 30],
  iconAnchor: [15, 30]
});
const ATTRIBUTION = {
  attribution:
    '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
};

L.Map.addInitHook('addHandler', 'gestureHandling', LGH.GestureHandling);

function initLeafletMap(id) {
  const $parentRow = $('#' + id)
    .parent()
    .parent()
    .parent();
  const $geoLocationLatitude = $parentRow.find('[id$="geo_location_latitude"]');
  const $geoLocationLongitude = $parentRow.find('[id$="geo_location_longitude"]');

  let center = CENTER_OF_GERMANY;
  let zoom = DEFAULT_ZOOM_LEVEL;
  if ($geoLocationLatitude.val() && $geoLocationLongitude.val()) {
    // Set center to eventually existing lat lng values
    center = [$geoLocationLatitude.val(), $geoLocationLongitude.val()];
    // Set zoom more close to eventually existing lat lng values
    zoom = 13;
  }

  const map = L.map(id, {
    minZoom: 3,
    zoom,
    center,
    gestureHandling: true
  });

  const mapInModal =
    $('#' + id).data('map-in-modal') !== undefined ? $('#' + id).data('map-in-modal') : false;
  if (mapInModal) {
    window.map = window.map || {};
    window.map[id] = map;
  }

  let marker;
  if ($geoLocationLatitude.val() && $geoLocationLongitude.val()) {
    // Set marker for eventually existing lat lng values
    marker = L.marker(center, { icon: ICON }).addTo(map);
  }

  const mapClick =
    $('#' + id).data('map-click') !== undefined ? $('#' + id).data('map-click') : true;
  if (mapClick) {
    map.on('click', function (e) {
      const lat = e.latlng.lat;
      const lng = e.latlng.lng;

      // Clear existing marker before setting a new one
      if (marker != undefined) {
        map.removeLayer(marker);
      }

      // Set the new marker on clicked position
      marker = L.marker([lat, lng], { icon: ICON }).addTo(map);

      $geoLocationLatitude.val(lat);
      $geoLocationLongitude.val(lng);
    });
  }

  L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', ATTRIBUTION).addTo(map);
}

function initLeafletMapTour(id) {
  let center = CENTER_OF_GERMANY;
  let zoom = DEFAULT_ZOOM_LEVEL;

  const tourCoordinates = JSON.parse(
    $('#' + id)
      .siblings('[hidden="tour-coordinates"]')
      .text()
  );

  if (tourCoordinates?.length) {
    const firstTourCoordinate = tourCoordinates[0];
    center = [firstTourCoordinate.lat, firstTourCoordinate.lng];
    zoom = 11;

    const map = L.map(id, {
      minZoom: 3,
      zoom,
      center,
      gestureHandling: true
    });

    L.marker([firstTourCoordinate.lat, firstTourCoordinate.lng], { icon: ICON }).addTo(map);

    L.polyline(tourCoordinates, {
      color: '#11223f',
      weight: 5,
      opacity: 0.75,
      smoothFactor: 1
    }).addTo(map);

    const lastTourCoordinate = tourCoordinates[tourCoordinates.length - 1];
    L.marker([lastTourCoordinate.lat, lastTourCoordinate.lng], { icon: ICON }).addTo(map);

    L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', ATTRIBUTION).addTo(map);
  }
}

$(function () {
  // Check if map container exists on page per interval and init maps in a loop when found
  const initLeafletMapInterval = setInterval(function () {
    if ($('.leafletMap').length) {
      clearInterval(initLeafletMapInterval);

      $('.leafletMapTour').each(function () {
        initLeafletMapTour(this.id);
      });

      $('.leafletMap:not(.leafletMapTour)').each(function () {
        initLeafletMap(this.id);
      });
    }
  }, 100);

  setTimeout(function () {
    clearInterval(initLeafletMapInterval);
  }, 4000);
});
