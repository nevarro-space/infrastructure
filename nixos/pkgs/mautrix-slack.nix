{ lib, fetchFromGitHub, buildGoModule, olm }:

buildGoModule {
  pname = "mautrix-slack";
  version = "unstable-2023-07-26";

  src = fetchFromGitHub {
    owner = "mautrix";
    repo = "slack";
    rev = "4530ff397d08d93b673cd71da4c2a75d969ca0df";
    hash = "sha256-zq5Qzdw6MhBJDMmi2SWHTEyOghpfLiQOEf0e2Fn+ww8=";
  };

  buildInputs = [ olm ];

  vendorHash = "sha256-Adfz6mHYa22OqEZZHrvst31XdZFo7LuxQI20whq3Zes=";

  meta = with lib; {
    homepage = "https://github.com/mautrix/slack";
    description = " A Matrix-Slack puppeting bridge";
    license = licenses.agpl3Plus;
    maintainers = with maintainers; [ sumnerevans ];
  };
}
