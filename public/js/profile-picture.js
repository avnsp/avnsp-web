var imgProfile = document.querySelector('img.profile');
var cropper = new Cropper.default(imgProfile);

document.querySelector('input[type=file]').addEventListener('change', function () {
  var file = this.files[0];
  if (!file) return;
  var reader = new FileReader();
  reader.onloadend = function () {
    var cropperImage = cropper.getCropperImage();
    if (cropperImage) cropperImage.src = reader.result;
  };
  reader.readAsDataURL(file);
});

document.getElementById('form-profile').addEventListener('submit', function (e) {
  e.preventDefault();
  var selection = cropper.getCropperSelection();
  if (!selection) return;

  var btn = e.target.querySelector('button[type=submit]');
  var status = document.getElementById('upload-status');

  btn.disabled = true;
  btn.textContent = 'Laddar upp\u2026';
  status.className = 'alert alert-info';
  status.textContent = 'Laddar upp din profilbild\u2026';

  selection.$toCanvas().then(function (canvas) {
    canvas.toBlob(function (blob) {
      var formData = new FormData(e.target);
      formData.append('cropped', blob);
      fetch('/member/profile-picture', { method: 'POST', body: formData })
        .then(function (res) {
          if (!res.ok) throw new Error(res.statusText);
          status.className = 'alert alert-success';
          status.textContent = 'Profilbilden har sparats!';
          btn.textContent = 'Spara';
          btn.disabled = false;
        })
        .catch(function () {
          status.className = 'alert alert-danger';
          status.textContent = 'Uppladdningen misslyckades. F\u00f6rs\u00f6k igen.';
          btn.textContent = 'Spara';
          btn.disabled = false;
        });
    });
  });
});
