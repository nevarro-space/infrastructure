{ lib, fetchFromGitHub, buildGoModule, olm }:

buildGoModule rec {
  pname = "msclinkbot";
  version = "unstable-2022-04-28";

  src = fetchFromGitHub {
    owner = "beeper";
    repo = "msc-link-bot";
    rev = "2c4807dd3c9c001a0b90bf9ed1fe2a8d07b76ce5";
    sha256 = "sha256-/AVRIZTunByy8iTrB4Gfs6tRsKqrDtl9NILgxfSYXYE=";
  };

  buildInputs = [ olm ];

  vendorSha256 = "sha256-GyY1z6R/IImCHtomg2qx7E8tn+hFXIGgDWbbKRHvkIM=";

  meta = with lib; {
    homepage = "https://git.hnitbjorg.xyz/~edwargix/msc-link-bot";
    description = "A re-write of @msclinkbot:matrix.org with support for encrypted rooms.";
    license = licenses.mit;
    maintainers = with maintainers; [ sumnerevans ];
  };
}
