var COLORS = ['#7cb5ec','#434348','#90ed7d','#f7a35c','#8085e9','#f15c80','#e4d354','#2b908f','#f45b5b','#91e8e1'];

var streamEl = document.getElementById('stream-data');
var attendees = JSON.parse(streamEl.dataset.attendees);
var seriesData = JSON.parse(streamEl.dataset.purchases);
var partyId = streamEl.dataset.partyId;
var mqttUser = streamEl.dataset.mqttUser;
var mqttPass = streamEl.dataset.mqttPass;

function renderChart() {
  var chart = document.getElementById('chart');
  var legend = document.getElementById('legend');
  chart.innerHTML = '';
  legend.innerHTML = '';

  var maxTotal = 0;
  for (var i = 0; i < attendees.length; i++) {
    var total = 0;
    for (var s = 0; s < seriesData.length; s++) {
      total += (seriesData[s].data[i] || 0);
    }
    if (total > maxTotal) maxTotal = total;
  }
  if (maxTotal === 0) maxTotal = 1;

  for (var s = 0; s < seriesData.length; s++) {
    var item = document.createElement('div');
    item.className = 'legend-item';
    var swatch = document.createElement('div');
    swatch.className = 'legend-swatch';
    swatch.style.background = COLORS[s % COLORS.length];
    item.appendChild(swatch);
    item.appendChild(document.createTextNode(seriesData[s].name));
    legend.appendChild(item);
  }

  for (var i = 0; i < attendees.length; i++) {
    var group = document.createElement('div');
    group.className = 'chart-group';
    var bars = document.createElement('div');
    bars.className = 'chart-bars';
    for (var s = 0; s < seriesData.length; s++) {
      var val = seriesData[s].data[i] || 0;
      var bar = document.createElement('div');
      bar.className = 'chart-bar';
      bar.style.height = (val / maxTotal * 500) + 'px';
      bar.style.background = COLORS[s % COLORS.length];
      bar.title = seriesData[s].name + ': ' + val;
      bars.appendChild(bar);
    }
    group.appendChild(bars);
    var label = document.createElement('div');
    label.className = 'chart-label';
    label.textContent = attendees[i];
    group.appendChild(label);
    chart.appendChild(group);
  }
}

renderChart();

// MQTT live updates
function onConnect() {
  console.log("onConnect");
  client.subscribe("mqtt-bridge/" + partyId);
}
function onConnectionLost(responseObject) {
  if (responseObject.errorCode !== 0) {
    console.log("onConnectionLost:", responseObject.errorMessage);
    setTimeout(function() { client.connect(connectOptions); }, 5000);
  }
}
function onMessageArrived(message) {
  seriesData = JSON.parse(message.payloadString);
  renderChart();
}

var client = new Paho.MQTT.Client('m21.cloudmqtt.com', 33848, "avnsp-" + partyId);
client.onConnectionLost = onConnectionLost;
client.onMessageArrived = onMessageArrived;
var connectOptions = {
  useSSL: true,
  userName: mqttUser,
  password: mqttPass,
  onSuccess: onConnect
};
client.connect(connectOptions);
