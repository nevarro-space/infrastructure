{ lib, fetchFromGitHub, buildGoModule, olm }:

buildGoModule rec {
  pname = "mautrix-slack";
  version = "unstable-2023-07-26";

  src = fetchFromGitHub {
    owner = "mautrix";
    repo = "slack";
    rev = "cb748dbc825f3aa310408f215470aea67eb736bb";
    sha256 = "sha256-Xsc1DS1QBAldWFxAL2cDhhYl9GHeWCL/KTQFduJ5KLY=";
  };

  buildInputs = [ olm ];

  vendorSha256 = "sha256-OBaxcIn+xw9g/Rh6lL6SfcmKWFkirBM0aV86hVfE93Q=";

  meta = with lib; {
    homepage = "https://github.com/mautrix/slack";
    description = " A Matrix-Slack puppeting bridge";
    license = licenses.agpl3Plus;
    maintainers = with maintainers; [ sumnerevans ];
  };
}
