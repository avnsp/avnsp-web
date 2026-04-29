var invitationDialog = document.getElementById('invitation-confirmation');

if (invitationDialog) {
  document.addEventListener('click', function(e) {
    var openBtn = e.target.closest('button[data-action="open-invitation-confirmation"]');
    var closeBtn = e.target.closest('button[data-action="close-invitation-confirmation"]');

    if (openBtn) {
      if (invitationDialog.showModal) {
        invitationDialog.showModal();
      } else {
        invitationDialog.setAttribute('open', '');
      }
    } else if (closeBtn) {
      if (invitationDialog.close) {
        invitationDialog.close();
      } else {
        invitationDialog.removeAttribute('open');
      }
    }
  });
}
