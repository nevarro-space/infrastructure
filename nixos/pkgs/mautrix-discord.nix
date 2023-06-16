{ lib, fetchFromGitHub, buildGoModule, olm }:

buildGoModule rec {
  pname = "mautrix-discord";
  version = "unstable-2023-06-16";

  src = fetchFromGitHub {
    owner = "mautrix";
    repo = "discord";
    rev = "00465bb71509b984614ed41fa4f147a9d6bd4b3a";
    sha256 = "sha256-2eYkYEoWo91ndKy7lI8JrjK7X7oPNLfws0XjpFvMICM=";
  };

  buildInputs = [ olm ];

  vendorSha256 = "sha256-wTJ2xcTFEU6+v5EQs+olKoGc9C5cktVOlnWP8CWMk4M=";

  meta = with lib; {
    homepage = "https://github.com/mautrix/discord";
    description = " A Matrix-Discord puppeting bridge";
    license = licenses.agpl3Plus;
    maintainers = with maintainers; [ sumnerevans ];
  };
}
