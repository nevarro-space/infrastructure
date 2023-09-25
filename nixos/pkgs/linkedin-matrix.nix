{ lib, fetchFromGitHub, python3 }: with python3.pkgs;
let
  linkedin-messaging = callPackage ./linkedin-messaging.nix { };
in
buildPythonPackage rec {
  pname = "linkedin-matrix";
  version = "0.5.5a1";

  src = fetchFromGitHub {
    owner = "beeper";
    repo = "linkedin";
    rev = "2cae15ee08e64bdba876f33d31404c04bde29823";
    sha256 = "sha256-/N7QYD7WEjULRop3U5TTm+bCDzyPMBGQQKA5eNYrL7I=";
  };

  postPatch = ''
    # the version mangling in mautrix_signal/get_version.py interacts badly with pythonRelaxDepsHook
    substituteInPlace setup.py \
      --replace 'version=version' 'version="${version}"'
  '';


  nativeBuildInputs = [
    pythonRelaxDepsHook
  ];

  pythonRelaxDeps = [
    "asyncpg"
  ];

  propagatedBuildInputs = [
    aiohttp
    aiosqlite
    asyncpg
    CommonMark
    linkedin-messaging
    mautrix
    pillow
    prometheus_client
    pycryptodome
    python-olm
    python_magic
    ruamel-yaml
    systemd
    unpaddedbase64
  ];

  doCheck = false;

  postInstall = ''
    mkdir -p $out/bin

    # Make a little wrapper for running linkedin-matrix with its dependencies
    echo "$linkedinMatrixScript" > $out/bin/linkedin-matrix
    echo "#!/bin/sh
      exec python -m linkedin_matrix \"\$@\"
    " > $out/bin/linkedin-matrix
    chmod +x $out/bin/linkedin-matrix
    wrapProgram $out/bin/linkedin-matrix \
      --set PATH ${python3}/bin \
      --set PYTHONPATH "$PYTHONPATH"
  '';

  pythonImportsCheck = [ "linkedin_matrix" ];

  meta = with lib; {
    description = "A LinkedIn Messaging <-> Matrix bridge.";
    homepage = "https://github.com/beeper/linkedin";
    license = licenses.asl20;
    maintainers = [ maintainers.sumnerevans ];
  };
}
