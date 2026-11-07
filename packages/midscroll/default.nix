# Stolen from the PR: https://github.com/VPavliashvili/midscroll-flake/blob/main/flake.nix

{
  lib,
  stdenv,
  makeWrapper,
  fetchFromGitHub,
  python3,
  systemd,
  gtk4-layer-shell,
  kdotool,
  xprop,
  wrapGAppsHook4,
  gobject-introspection,
  gnome,
  librsvg,
  gtk4,
  hicolor-icon-theme,
  ...
}:
let
  pythonEnv = python3.withPackages (ps: [
    ps.evdev
    ps.pygobject3
    ps.pycairo
  ]);
in
  stdenv.mkDerivation (finalAttrs: {
    pname = "midscroll";
    version = "1.15"; # latest release version when writing this flake

    src = fetchFromGitHub {
      owner = "gnhen";
      repo = "midscroll";
      tag = "v${finalAttrs.version}";
      hash = "sha256-x/pmdmkCNtsng57jSYpvfNTFHzsm9Qddp2sFXqEQzyQ=";
    };

    nativeBuildInputs = [
      makeWrapper
      wrapGAppsHook4
      gobject-introspection
    ];

    buildInputs = [
      gtk4
      gtk4-layer-shell
      librsvg
      hicolor-icon-theme
    ];

    dontConfigure = true;
    dontBuild = true;

    installPhase = ''
      runHook preInstall

      install -Dm755 midscroll.py         $out/bin/midscroll
      install -Dm755 midscroll-overlay.py  $out/bin/midscroll-overlay
      install -Dm755 midscroll-settings.py $out/bin/midscroll-settings
      install -Dm755 midscroll-apply.py    $out/bin/midscroll-apply

      install -Dm644 io.github.gnhen.midscroll.Settings.desktop \
        $out/share/applications/io.github.gnhen.midscroll.Settings.desktop
      install -Dm644 io.github.gnhen.midscroll.Settings.metainfo.xml \
        $out/share/metainfo/io.github.gnhen.midscroll.Settings.metainfo.xml
      install -Dm644 io.github.gnhen.midscroll.policy \
        $out/share/polkit-1/actions/io.github.gnhen.midscroll.policy

      install -Dm644 icons/move-vertical.svg $out/share/midscroll/move-vertical.svg
      install -Dm644 icons/move-vertical.svg \
        $out/share/icons/hicolor/scalable/apps/midscroll.svg

      install -Dm644 midscroll.conf $out/share/midscroll/midscroll.conf

      runHook postInstall
    '';

    dontWrapGApps = true;

    postInstall = ''
      export GDK_PIXBUF_MODULE_FILE="${
        gnome._gdkPixbufCacheBuilder_DO_NOT_USE { extraLoaders = [ librsvg ]; }
      }"
    '';

    postFixup = ''
      for f in midscroll midscroll-overlay midscroll-settings midscroll-apply; do
        sed -i "1s|^#!.*|#!${pythonEnv}/bin/python3|" "$out/bin/$f"
      done

      substituteInPlace "$out/share/polkit-1/actions/io.github.gnhen.midscroll.policy" \
        --replace-fail "/usr/bin/midscroll-apply" "$out/bin/midscroll-apply"
      substituteInPlace "$out/bin/midscroll-settings" \
        --replace-fail "/usr/bin/midscroll-apply" "$out/bin/midscroll-apply"

      wrapProgram "$out/bin/midscroll-apply" \
        --prefix PATH : ${lib.makeBinPath [ systemd ]}

      # below is midscroll-overlay related stuff
      # its is important to know that it only works on KDE
      # with kdotool, which is also mentioned on the github readme
      # so there is also option to enable disable its service
      # `services.midscroll.overlay.enable = false;`
      layerShellLib=$(find ${gtk4-layer-shell}/lib -maxdepth 1 -name 'libgtk4-layer-shell.so*' | sort | head -n1)
      wrapProgram "$out/bin/midscroll-overlay" \
        "''${gappsWrapperArgs[@]}" \
        --prefix PATH : ${
          lib.makeBinPath [
            kdotool
            xprop
          ]
        } \
        --set-default LD_PRELOAD "$layerShellLib"

      wrapProgram "$out/bin/midscroll-settings" \
        "''${gappsWrapperArgs[@]}"
    '';

    meta = {
      description = "FOSS Middle Mouse Scroll replacement for Linux";
      homepage = "https://github.com/gnhen/midscroll";
      license = lib.licenses.unlicense;
      platforms = lib.platforms.linux;
      mainProgram = "midscroll";
    };
  })