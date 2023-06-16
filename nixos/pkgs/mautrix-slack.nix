{ lib, fetchFromGitHub, buildGoModule, olm }:

buildGoModule rec {
  pname = "mautrix-slack";
  version = "unstable-2023-06-16";

  src = fetchFromGitHub {
    owner = "mautrix";
    repo = "slack";
    rev = "e9074423a08f7bbb9f489fae9a3d0d64c5d56c1c";
    sha256 = "sha256-8Goz2LzIP5e3NluPI676C4GKUrTWBNnp+VB3o/wQt90=";
  };

  buildInputs = [ olm ];

  vendorSha256 = "sha256-rG5z2UqfQgG+c/OF3mTLvX6O5RhouUgP9++5CA6YCw4=";

  meta = with lib; {
    homepage = "https://github.com/mautrix/slack";
    description = " A Matrix-Slack puppeting bridge";
    license = licenses.agpl3Plus;
    maintainers = with maintainers; [ sumnerevans ];
  };
}
