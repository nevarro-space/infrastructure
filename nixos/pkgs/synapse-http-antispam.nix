{
  lib,
  python3,
  fetchFromGitHub,
  matrix-synapse-unwrapped,
  nix-update-script,
}:

python3.pkgs.buildPythonPackage rec {
  pname = "synapse-http-antispam";
  version = "0.2.0";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "maunium";
    repo = "synapse-http-antispam";
    rev = "v${version}";
    sha256 = "sha256-b/s4hB9KsI07B+4NsDlOq2maQEl7UXj11QBN39I1REs=";
  };

  build-system = [ python3.pkgs.hatchling ];

  pythonImportsCheck = [ "synapse_http_antispam" ];

  buildInputs = [ matrix-synapse-unwrapped ];
  propagatedBuildInputs = [ python3.pkgs.twisted ];

  passthru.updateScript = nix-update-script { };

  meta = with lib; {
    description = "Synapse module that forwards spam checking to an HTTP server";
    homepage = "https://github.com/maunium/synapse-http-antispam";
    license = licenses.mit;
    maintainers = with maintainers; [ sumnerevans ];
  };
}
