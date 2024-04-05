{ lib, fetchFromGitHub, buildGoModule, olm }:

buildGoModule {
  pname = "mautrix-slack";
  version = "unstable-2024-04-05";

  src = fetchFromGitHub {
    owner = "mautrix";
    repo = "slack";
    rev = "9af0d73bee280af5858e4a36bbad721c95b73da8";
    hash = "sha256-mEZBGYrFTa5mVq6TnZhEkgcOmWhn836Y6zJqGzK0jeM=";
  };

  buildInputs = [ olm ];

  vendorHash = "sha256-FL0wObZIvGV9V7pLmrxTILQ/TGEMSH8/2wFPlu6idcA=";

  meta = with lib; {
    homepage = "https://github.com/mautrix/slack";
    description = " A Matrix-Slack puppeting bridge";
    license = licenses.agpl3Plus;
    maintainers = with maintainers; [ sumnerevans ];
  };
}
