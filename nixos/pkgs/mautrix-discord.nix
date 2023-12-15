{ lib, fetchFromGitHub, buildGoModule, olm }:

buildGoModule {
  pname = "mautrix-discord";
  version = "unstable-2023-12-05";

  src = fetchFromGitHub {
    owner = "mautrix";
    repo = "discord";
    rev = "643d4c6e391aa5908e3027f507a44942ee15a07f";
    hash = "sha256-KrDV3FXEZlbx0/LFcDkol6Zm/HAC26lMj0XQ6Le5ark=";
  };

  buildInputs = [ olm ];

  vendorHash = "sha256-rbz6bWBl2rmfHuszjKoWZP4/B4F90MUtR5nAIXCU3pg=";

  meta = with lib; {
    homepage = "https://github.com/mautrix/discord";
    description = " A Matrix-Discord puppeting bridge";
    license = licenses.agpl3Plus;
    maintainers = with maintainers; [ sumnerevans ];
  };
}
