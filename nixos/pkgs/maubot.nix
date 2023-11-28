{ lib, fetchpatch, fetchPypi, fetchFromGitHub, python3 }:
python3.pkgs.buildPythonPackage rec {
  pname = "maubot";
  version = "unstable-2023-06-02";

  src = fetchFromGitHub {
    owner = "maubot";
    repo = pname;
    rev = "bf8ae9eb5aba7eaac70838e323228db910c27171";
    hash = "sha256-qfIjI3vEnb0aQBEjTwhzp/c43AYL7aDQiBJRMeSdnN0=";
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

  postPatch = ''
    sed -i -e 's/aiosqlite.*/aiosqlite/' requirements.txt
    sed -i -e 's/SQLAlchemy.*/SQLAlchemy/' requirements.txt
    sed -i -e 's/bcrypt.*/bcrypt/' requirements.txt
    sed -i -e 's/mautrix.*/mautrix/' requirements.txt
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
