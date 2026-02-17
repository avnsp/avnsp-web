var imgProfile = document.querySelector('img.profile');
var cropper = new Cropper.default(imgProfile);

document.querySelector('input[type=file]').addEventListener('change', function () {
  var file = this.files[0];
  if (!file) return;
  var reader = new FileReader();
  reader.onloadend = function () {
    cropper.replace(reader.result);
  };
  reader.readAsDataURL(file);
});

document.getElementById('form-profile').addEventListener('submit', function (e) {
  e.preventDefault();
  var selection = cropper.getCropperSelection();
  if (!selection) return;
  selection.$toCanvas().then(function (canvas) {
    canvas.toBlob(function (blob) {
      var formData = new FormData(e.target);
      formData.append('cropped', blob);
      fetch('/member/profile-picture', { method: 'POST', body: formData })
        .then(function () { location.reload(); })
        .catch(function () { console.log('Upload error'); });
    });
  });
});
