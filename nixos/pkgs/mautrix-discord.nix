{ lib, fetchFromGitHub, buildGoModule, olm }:

buildGoModule rec {
  pname = "mautrix-discord";
  version = "unstable-2023-05-14";

  src = fetchFromGitHub {
    owner = "mautrix";
    repo = "discord";
    rev = "ad8efb864bd72a2060436117c8f299d365091c45";
    sha256 = "sha256-2gzJqCoydttkui+F9ZAQyZnFCJr+FPCWElh3jaz5Hag=";
  };

  buildInputs = [ olm ];

  vendorSha256 = "sha256-yZhgfarexBCmDinmVB3BYo6sQ/UAwr/Yi1ilj0wgH08=";

  meta = with lib; {
    homepage = "https://github.com/mautrix/discord";
    description = " A Matrix-Discord puppeting bridge";
    license = licenses.agpl3Plus;
    maintainers = with maintainers; [ sumnerevans ];
  };
}
