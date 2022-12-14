var L = require('leaflet/dist/leaflet');
var LGH = require('leaflet-gesture-handling/dist/leaflet-gesture-handling');

/* eslint-disable func-names */
var CENTER_OF_GERMANY = [51.3127114, 9.4797461];
var DEFAULT_ZOOM_LEVEL = 6;

function initLeafletMap(id) {
  var $parentRow = $('#' + id).parent().parent().parent();
  var $geoLocationLatitude = $parentRow.find('[id$="geo_location_latitude"]');
  var $geoLocationLongitude = $parentRow.find('[id$="geo_location_longitude"]');

  var center = CENTER_OF_GERMANY;
  var zoom = DEFAULT_ZOOM_LEVEL;
  if ($geoLocationLatitude.val() && $geoLocationLongitude.val()) {
    // Set center to eventually existing lat lng values
    center = [$geoLocationLatitude.val(), $geoLocationLongitude.val()];
    // Set zoom more close to eventually existing lat lng values
    zoom = 13;
  }

  L.Map.addInitHook('addHandler', 'gestureHandling', LGH.GestureHandling);

  var map = L.map(id, {
    minZoom: 3,
    zoom,
    center,
    gestureHandling: true
  });

  var mapInModal = $('#' + id).data('map-in-modal') !== undefined ? $('#' + id).data('map-in-modal') : false;
  if (mapInModal) {
    window.map = window.map || {};
    window.map[id] = map;
  }

  var icon = L.icon({
    iconUrl: '/marker.svg',
    iconSize: [30, 30],
    iconAnchor: [15, 30]
  });

  var marker;
  if ($geoLocationLatitude.val() && $geoLocationLongitude.val()) {
    // Set marker for eventually existing lat lng values
    marker = L.marker(center, { icon: icon }).addTo(map);
  }

  var mapClick = $('#' + id).data('map-click') !== undefined ? $('#' + id).data('map-click') : true;
  if (mapClick) {
    map.on('click', function(e) {
      var lat = e.latlng.lat;
      var lng = e.latlng.lng;

      // Clear existing marker before setting a new one
      if (marker != undefined) {
        map.removeLayer(marker);
      }

      // Set the new marker on clicked position
      marker = L.marker([lat, lng], { icon: icon }).addTo(map);

      $geoLocationLatitude.val(lat);
      $geoLocationLongitude.val(lng);
    });
  }

  L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
    attribution:
      '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
  }).addTo(map);
}

$(function() {
  // Check if map exists on page after a short timeout being rendered and init maps in a loop
  setTimeout(function() {
    $('.leafletMap').each(function() {
      initLeafletMap(this.id);
    });
  }, 500);
});
/* eslint-ensable func-names */
