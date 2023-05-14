{ lib, fetchFromGitHub, buildGoModule, olm }:

buildGoModule rec {
  pname = "mautrix-slack";
  version = "unstable-2023-05-14";

  src = fetchFromGitHub {
    owner = "mautrix";
    repo = "slack";
    rev = "5a967e49bd48c95f326d530dfa4f4fb3ce9af4c9";
    sha256 = "sha256-wdKzpM+f8qqYv8Q1B36AAAAAAAAAAAIqE0N/bpUzdq0=";
  };

  buildInputs = [ olm ];

  vendorSha256 = "sha256-0IL0C+c/yZh1OxzAAAAAAF5qUagLzQImygTa4DQunio=";

  meta = with lib; {
    homepage = "https://github.com/mautrix/slack";
    description = " A Matrix-Slack puppeting bridge";
    license = licenses.agpl3Plus;
    maintainers = with maintainers; [ sumnerevans ];
  };
}
