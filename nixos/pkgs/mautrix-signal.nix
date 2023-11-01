{ lib, fetchFromGitHub, buildGoModule, olm }:

buildGoModule rec {
  pname = "mautrix-signal";
  version = "unstable-2023-11-01";

  src = fetchFromGitHub {
    owner = "mautrix";
    repo = "signalgo";
    rev = "870e776422db80427e63e2c35bcf79bdd6d2602f";
    hash = "sha256-zqF59BEkeBs4X7UZtwB5KpCOVROjBcIV9/Xlwdj8bL8=";
  };

  buildInputs = [ olm ];

  vendorSha256 = "sha256-Adfz6mHYa22OqAAAAAAAAAAAAAAA7LuxQI20whq3Zes=";

  meta = with lib; {
    homepage = "https://github.com/mautrix/slack";
    description = " A Matrix-Slack puppeting bridge";
    license = licenses.agpl3Plus;
    maintainers = with maintainers; [ sumnerevans ];
  };
}
