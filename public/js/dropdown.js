// Closes the user menu (<details class="dropdown">) when clicking outside it.
document.addEventListener('click', function (e) {
  document.querySelectorAll('details.dropdown[open]').forEach(function (menu) {
    if (!menu.contains(e.target)) menu.removeAttribute('open');
  });
});
