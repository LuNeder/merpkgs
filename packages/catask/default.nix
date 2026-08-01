{
  lib,
  stdenv,
  fetchFromGitea,
  python314Packages,
  postgresql,
  makeWrapper,
}:

let
  python = python314Packages;
in
stdenv.mkDerivation (finalAttrs: {
  pname = "catask";
  version = "2.7.6";

  src = fetchFromGitea {
    domain = "codeberg.org";
    owner = "catask-org";
    repo = "catask";
    tag = "v${finalAttrs.version}";
    hash = "sha256-KMS/9SfqlNCqAowXgZNlsJllhVVbJcTm29UN9xBUsno=";
  };

  propagatedBuildInputs = [
    (python.python.withPackages (
      ps: with ps; [
        flask
        gunicorn
        markupsafe
        pillow
        python-dotenv
        psycopg
        humanize
        mistune
        bleach
        pathlib2
        flask-babel
        flask-compress
        requests
        yoyo-migrations
        ago
        lupa
        authlib
        sentry-sdk
        mastodon-py
        nh3
      ]
    ))
    postgresql
    makeWrapper
  ];

  installPhase = ''
    mkdir -p $out/share/catask
    cp -R * -t $out/share/catask
  '';

  # Semi-opinionated script to allow running, more configuration is available in the NixOS module
  preFixup = ''
    makeWrapper "${lib.getExe python.gunicorn}" "$out/bin/catask" \
      --add-flags "-w" \
      --add-flags "4" \
      --add-flags "--pythonpath" \
      --add-flags "$out/share/catask" \
      --add-flags "app:app" \
      --prefix PATH : "${lib.makeBinPath finalAttrs.propagatedBuildInputs}"

      makeWrapper "${lib.getExe python.flask}" "$out/bin/catask-init-db" \
      --chdir "$out/share/catask" \
      --add-flags "init-db" \
      --set-default PYTHONDONTWRITEBYTECODE "true" \
      --prefix PATH : "${lib.makeBinPath finalAttrs.propagatedBuildInputs}"
  '';

  meta = {
    description = "CatAsk is a simple & easy to use Q&A software that makes answering questions easier.";
    homepage = "https://catask.org/";
    license = lib.licenses.agpl3Plus;
    platforms = lib.platforms.unix;
    maintainers = [ lib.maintainers.luNeder ];
    mainProgram = "catask";
  };
})
