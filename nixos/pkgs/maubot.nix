{ lib
, fetchpatch
, fetchPypi
, fetchFromGitHub
, python3
, yarn
, fixup_yarn_lock
, nodejs
, fetchYarnDeps
}:
python3.pkgs.buildPythonPackage rec {
  pname = "maubot";
  version = "unstable-2023-05-14";

  src = fetchFromGitHub {
    owner = "maubot";
    repo = pname;
    rev = "b4e8e5bfbb4c668e5e0a4cf09c44150dd77ff17c";
    sha256 = "sha256-qfIjI3vEnb0aQBEjTwhzp/c43AYL7aDQiBJRMeSdnN0=";
  };

  propagatedBuildInputs = with python3.pkgs; [
    aiohttp
    aiosqlite
    asyncpg
    attrs
    bcrypt
    click
    colorama
    CommonMark
    jinja2
    mautrix
    packaging
    python-socks
    questionary
    ruamel-yaml
    (sqlalchemy.overridePythonAttrs (old: rec {
      version = "1.4.48";
      src = fetchPypi {
        inherit (old) pname;
        inherit version;
        hash = "sha256-tHvChwltmJoIOM6W99jpZpFKJNqHftQadTHUS1XNuN8=";
      };
      doCheck = false;
    }))
    systemd
    python-olm
    pycryptodome
    unpaddedbase64
  ];

  nativeBuildInputs = [ fixup_yarn_lock yarn nodejs ];

  offlineCache = fetchYarnDeps {
    yarnLock = src + "/maubot/management/frontend/yarn.lock";
    sha256 = "sha256-VBPZbtqF9u63yRgk0PObhUMvV8s7UXSs6nr87cPeLz4=";
  };

  configurePhase = ''
    runHook preConfigure

    export HOME=$PWD/tmp
    mkdir -p $HOME

    pushd maubot/management/frontend
    fixup_yarn_lock yarn.lock
    yarn config --offline set yarn-offline-mirror $offlineCache
    yarn install --offline --frozen-lockfile --ignore-platform --ignore-scripts --no-progress --non-interactive
    patchShebangs node_modules
    popd

    runHook postConfigure
  '';

  preBuild = ''
    pushd maubot/management/frontend
    yarn build
    popd
  '';

  postPatch = ''
    sed -i -e 's/aiosqlite>=0.16,<0.19/aiosqlite<0.20,>=0.16/' requirements.txt
    sed -i -e 's/SQLAlchemy>=1,<1.4/SQLAlchemy>=1,<1.5/' requirements.txt
    sed -i -e 's/bcrypt>=3,<4/bcrypt/' requirements.txt
  '';

  postInstall = ''
    mkdir -p $out/bin

    cat <<-END >$out/bin/maubot
    #!/bin/sh
    PYTHONPATH="$PYTHONPATH" exec ${python3}/bin/python -m maubot "\$@"
    END
    chmod +x $out/bin/maubot

    cat <<-END >$out/bin/standalone
    #!/bin/sh
    PYTHONPATH="$PYTHONPATH" exec ${python3}/bin/python -m maubot.standalone "\$@"
    END
    chmod +x $out/bin/standalone
  '';

  doCheck = false;

  meta = with lib; {
    description = "A bouncer-style Matrix-IRC bridge.";
    homepage = "https://github.com/maubot/maubot";
    license = licenses.agpl3Plus;
    maintainers = [ maintainers.sumnerevans ];
  };
}
