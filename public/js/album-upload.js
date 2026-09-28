var form = document.getElementById('photo-upload');

if (form) {
  var input = document.getElementById('photo-files');
  var captions = document.getElementById('photo-captions');
  var status = document.getElementById('upload-status');
  var btn = form.querySelector('button[type=submit]');

  input.addEventListener('change', function () {
    captions.innerHTML = '';
    Array.prototype.forEach.call(input.files, function (file, i) {
      var group = document.createElement('div');
      group.className = 'form-group';
      var label = document.createElement('label');
      label.htmlFor = 'photo-caption-' + i;
      label.textContent = 'Bildtext för ' + file.name;
      var field = document.createElement('input');
      field.type = 'text';
      field.id = 'photo-caption-' + i;
      field.name = 'captions[]';
      group.appendChild(label);
      group.appendChild(field);
      captions.appendChild(group);
    });
  });

  function show(kind, text) {
    status.className = 'alert alert-' + kind;
    status.textContent = text;
  }

  // Send one photo per request so large batches from a phone don't hit the
  // request timeout, and so one bad file doesn't stop the rest.
  form.addEventListener('submit', function (e) {
    e.preventDefault();
    var files = Array.prototype.slice.call(input.files);
    if (!files.length) return;
    var token = form.querySelector('input[name=authenticity_token]').value;
    var failed = [];
    btn.disabled = true;

    function next(i) {
      if (i === files.length) {
        btn.disabled = false;
        var done = files.length - failed.length;
        if (failed.length) {
          show('danger', done + ' av ' + files.length + ' bilder laddades upp. Misslyckades: ' + failed.join('; '));
        } else {
          show('success', done + ' bilder uppladdade. Sidan laddas om när de har bearbetats…');
          setTimeout(function () { window.location.reload(); }, 4000);
        }
        return;
      }
      show('info', 'Laddar upp bild ' + (i + 1) + ' av ' + files.length + '…');
      var data = new FormData();
      data.append('authenticity_token', token);
      data.append('files[]', files[i]);
      var caption = document.getElementById('photo-caption-' + i);
      data.append('captions[]', caption ? caption.value : '');
      fetch(form.action, {
        method: 'POST',
        body: data,
        headers: { 'X-Requested-With': 'XMLHttpRequest' }
      })
        .then(function (res) {
          if (res.ok) return;
          return res.text().then(function (msg) {
            failed.push(files[i].name + ' (' + (msg || res.status) + ')');
          });
        })
        .catch(function () {
          failed.push(files[i].name + ' (nätverksfel)');
        })
        .then(function () { next(i + 1); });
    }

    next(0);
  });
}
