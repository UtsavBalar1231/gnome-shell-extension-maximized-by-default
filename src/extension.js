const Meta = imports.gi.Meta;

let _windowCreatedId = null;

function enable() {
  if (_windowCreatedId !== null) {
    console.warn("Extension already enabled!");
    return;
  }

  _windowCreatedId = global.display.connect(
    "window-created",
    (display, window) => {
      const maximizeFlags = Meta.MaximizeFlags.BOTH;

      if (!window) {
        console.debug("Received null window object");
        return;
      }

      if (window.can_maximize()) {
        window.maximize(maximizeFlags);
        return;
      }

      console.debug(
        `Window ${window.get_title()} cannot be maximized, skipping`,
      );

      // unmaximize is still needed? (modern GNOME probably handles it)
      // window.unmaximize(maximizeFlags);  // Possibly obsolete now
    },
  );
}

function disable() {
  if (_windowCreatedId !== null) {
    global.display.disconnect(_windowCreatedId);
    _windowCreatedId = null;
  } else {
    console.warn("Extension already disabled!");
  }
}
