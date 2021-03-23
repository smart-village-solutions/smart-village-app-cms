const initLeafletMap = () => {
  // Leaflet Integration
  var map = L.map('leafletMap', {
    scrollWheelZoom: false,
    minZoom: 3,
  }).setView([ 51.3127114, 9.4797461], 6);

  var icon = L.icon({
    iconUrl: '/assets/marker.svg',
    iconSize:     [30, 30],
    iconAnchor:   [15, 30]
  });

  var marker = {};
  marker = L.marker([ 51.3127114, 9.4797461], {icon: icon}).addTo(map);
  map.on('click',function(e){
    lat = e.latlng.lat;
    lon = e.latlng.lng;

    // Clear existing marker
    if (marker != undefined) {
      map.removeLayer(marker);
    };

     marker = L.marker([lat,lon], {icon: icon}).addTo(map);
  });

  L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
    attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
  }).addTo(map);
};

$(function() {
  // Check if map exists on page
  if($('#leafletMap').length) {
    setTimeout(function () {
      initLeafletMap();
    }, 500);
  }
});