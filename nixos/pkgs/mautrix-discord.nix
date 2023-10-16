{ lib, fetchFromGitHub, buildGoModule, olm }:

buildGoModule rec {
  pname = "mautrix-discord";
  version = "unstable-2023-10-16";

  src = fetchFromGitHub {
    owner = "mautrix";
    repo = "discord";
    rev = "45359853de90f21cbe1b95340c89f7a60b1a0774";
    hash = "sha256-hksnD1RWK83JjVIZsKeK8bQobNmzIbm9drgU0VjiqLs=";
  };

  buildInputs = [ olm ];

  vendorSha256 = "sha256-+dmlJZPc2Tw9G64MeLPY5Rgml3UKEqAtgGI1ImRvMBU=";

  meta = with lib; {
    homepage = "https://github.com/mautrix/discord";
    description = " A Matrix-Discord puppeting bridge";
    license = licenses.agpl3Plus;
    maintainers = with maintainers; [ sumnerevans ];
  };
}
