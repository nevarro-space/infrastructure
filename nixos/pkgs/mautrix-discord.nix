{ lib, fetchFromGitHub, buildGoModule, olm }:

buildGoModule rec {
  pname = "mautrix-discord";
  version = "unstable-2023-07-26";

  src = fetchFromGitHub {
    owner = "mautrix";
    repo = "discord";
    rev = "ff0a9bcafa295e2080beac3e0df13c3fa606719f";
    sha256 = "sha256-VPKo2iIV2KZBJVuSXyVtqFxd83FEYMRhinnywS9Atwk=";
  };

  buildInputs = [ olm ];

  vendorSha256 = "sha256-AtXNoONC9PjHdkSPuk67+bIXP4P3Wa3oEcDi4zCMzUE=";

  meta = with lib; {
    homepage = "https://github.com/mautrix/discord";
    description = " A Matrix-Discord puppeting bridge";
    license = licenses.agpl3Plus;
    maintainers = with maintainers; [ sumnerevans ];
  };
}
