(function () {
  var button = document.querySelector('[data-christmas-toggle]');
  if (!button) return;
  var root = document.documentElement;
  function render() {
    var enabled = !root.classList.contains('christmas-off');
    button.setAttribute('aria-pressed', String(enabled));
    var label = enabled ? 'Turn off Christmas theme' : 'Turn on Christmas theme';
    button.setAttribute('aria-label', label);
    button.title = label;
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
