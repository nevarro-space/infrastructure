{ lib, fetchFromGitHub, buildGoModule, olm }:

buildGoModule rec {
  pname = "mautrix-slack";
  version = "unstable-2023-06-02";

  src = fetchFromGitHub {
    owner = "mautrix";
    repo = "slack";
    rev = "7e379049f1c0be2bb6d0b38eaff331f2eb000591";
    sha256 = "sha256-BZFAaQkUURM2+X+KztEHeNKckJT6jKvd+TA9VXh1oMo=";
  };

  buildInputs = [ olm ];

  vendorSha256 = "sha256-zLD06I6pE/BQss8C7WH2F5fid4npaB36mxfr8WitGFQ=";

  meta = with lib; {
    homepage = "https://github.com/mautrix/slack";
    description = " A Matrix-Slack puppeting bridge";
    license = licenses.agpl3Plus;
    maintainers = with maintainers; [ sumnerevans ];
  };
}
