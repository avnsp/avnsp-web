// Asks before submitting any form marked with data-confirm="question".
document.addEventListener('submit', function (e) {
  var question = e.target.getAttribute('data-confirm');
  if (question && !window.confirm(question)) e.preventDefault();
});
