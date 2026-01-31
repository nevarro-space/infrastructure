{
  lib,
  fetchFromGitHub,
  buildGoModule,
}:
buildGoModule {
  pname = "msclinkbot";
  version = "unstable-2024-07-12";

  src = fetchFromGitHub {
    owner = "beeper";
    repo = "msc-link-bot";
    rev = "a3ba1e978086d17025dcd26fb30a7e6a06bc447f";
    hash = "sha256-L0C3so6Dpsba+wS1EnkAcxYGseAALxe6PuJKlPl1ECs=";
  };

  tags = [ "goolm" ];

  vendorHash = "sha256-BzCzTrL0KxTfwg4qGPHabuv9AzmelDZ6kz2vQ0/Xr6A=";

  meta = with lib; {
    homepage = "https://git.hnitbjorg.xyz/~edwargix/msc-link-bot";
    description = "A re-write of @msclinkbot:matrix.org with support for encrypted rooms.";
    license = licenses.mit;
    maintainers = with maintainers; [ sumnerevans ];
  };
}
