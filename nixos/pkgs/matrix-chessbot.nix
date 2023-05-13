{ lib, fetchFromGitHub, buildGoModule, olm, imagemagick }:

buildGoModule rec {
  pname = "matrix-chessbot";
  version = "unstable-2023-05-11";

  src = fetchFromGitHub {
    owner = "nevarro-space";
    repo = "matrix-chessbot";
    rev = "f9a8e247f47da1b5fd51e76816d36302fbd46a89";
    sha256 = "sha256-lg3lw9PhvcNWGYEEaVJwwIt80QR3DvDcy4RXdLeuvh4=";
  };

  buildInputs = [
    olm
  ];

  propagatedBuildInputs = [
    imagemagick
  ];

  vendorSha256 = "sha256-wNA4s8DCWfxh1z0cnOn0mHKqbN0BHR7AkgUuK+Fzp9U=";

  meta = with lib; {
    homepage = "https://github.com/nevarro-space/matrix-chessbot";
    description = "A bot for playing chess via Matrix";
    license = licenses.mit;
    maintainers = with maintainers; [ sumnerevans ];
  };
}
