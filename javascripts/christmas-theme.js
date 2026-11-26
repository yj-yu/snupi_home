(function () {
  var button = document.querySelector('[data-christmas-toggle]');
  if (!button) return;
  var root = document.documentElement;
  function render() {
    var enabled = !root.classList.contains('christmas-off');
    button.setAttribute('aria-pressed', String(enabled));
    button.querySelector('[data-christmas-state]').textContent = enabled ? 'ON' : 'OFF';
  }
  render();
  button.addEventListener('click', function () {
    root.classList.toggle('christmas-off');
    try {
      localStorage.setItem('snupi-christmas', root.classList.contains('christmas-off') ? 'off' : 'on');
    } catch (error) {}
    render();
  });
}());
