function getMember(name) {
  var selector = '#members option[data-name="' + name + '"]';
  var member = document.querySelector(selector);
  return member.dataset;
}

function removeOrganizer(btn) {
  btn.closest('.input-group').remove();
}

function addOrganizer(btn) {
  var group = btn.closest('.input-group');
  var id_node = group.children[0];
  var name_node = group.children[1];
  var member = getMember(name_node.value);
  id_node.value = member.id;
  convertOrganizerInput(btn);
  renderTemplate();
}

function convertOrganizerInput(btn) {
  btn.classList.remove('btn-success');
  btn.classList.add('btn-danger');
  btn.dataset.action = 'remove';
  btn.textContent = '\u2715';
}

function renderTemplate() {
  var list = document.querySelector('#organizers');
  var t = document.querySelector('#new-organizer');
  var clone = document.importNode(t.content, true);
  list.appendChild(clone);
}

document.getElementById('organizers').addEventListener('click', function(e) {
  var btn = e.target.closest('button[data-action]');
  if (!btn) return;
  if (btn.dataset.action === 'remove') {
    removeOrganizer(btn);
  } else if (btn.dataset.action === 'add') {
    addOrganizer(btn);
  }
});

renderTemplate();
