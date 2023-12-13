{ lib, fetchFromGitHub, python3 }:
with python3.pkgs;
buildPythonPackage rec {
  pname = "linkedin-matrix";
  version = "0.5.5a2";

  src = fetchFromGitHub {
    owner = "beeper";
    repo = "linkedin";
    rev = "79d3b4cecf118c27a7492c0d349b3665ea563af3";
    hash = "sha256-jPiA5RbQC6l2eKHLypK+XbKRPPR/RLc3G8DEuQEzlMU=";
  };

  postPatch = ''
    # the version mangling in linkedin_matrix/get_version.py interacts badly with pythonRelaxDepsHook
    substituteInPlace setup.py \
      --replace 'version=version' 'version="${version}"'
  '';

  nativeBuildInputs = [ pythonRelaxDepsHook ];

  pythonRelaxDeps = [ "asyncpg" "dataclasses-json" ];

  propagatedBuildInputs = [
    aiohttp
    aiosqlite
    asyncpg
    beautifulsoup4
    CommonMark
    dataclasses-json
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

  pythonImportsCheck = [ "linkedin_matrix" "linkedin_messaging" ];

  meta = with lib; {
    description = "A LinkedIn Messaging <-> Matrix bridge.";
    homepage = "https://github.com/beeper/linkedin";
    license = licenses.asl20;
    maintainers = [ maintainers.sumnerevans ];
  };
}
