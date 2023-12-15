{ lib, fetchFromGitHub, buildGoModule }:
buildGoModule {
  pname = "msclinkbot";
  version = "unstable-2023-12-15";

  src = fetchFromGitHub {
    owner = "beeper";
    repo = "msc-link-bot";
    rev = "5319f21e3e696fca4bef4d566f7ae377c767180b";
    hash = "sha256-xYKJ+IJgr2vQKSlIQT1wUdJo8nHOi7eFg4+gDZfqZ8U=";
  };

  tags = [ "goolm" ];

  vendorHash = "sha256-foQaIMW0W3UQrPDQyb7utWEB+zsibKPk8o7dRol3AKA=";

  meta = with lib; {
    homepage = "https://git.hnitbjorg.xyz/~edwargix/msc-link-bot";
    description =
      "A re-write of @msclinkbot:matrix.org with support for encrypted rooms.";
    license = licenses.mit;
    maintainers = with maintainers; [ sumnerevans ];
  };
}
