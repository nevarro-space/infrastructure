{ lib, fetchFromGitHub, buildGoModule, olm }:

buildGoModule rec {
  pname = "mautrix-discord";
  version = "unstable-2023-06-02";

  src = fetchFromGitHub {
    owner = "mautrix";
    repo = "discord";
    rev = "8c57b7a69bb4a7b3dfff5f0b48968569ac5ec65c";
    sha256 = "sha256-S4ya7jzdQy4Q3o3ziNwYIpjzxo/vDEtH7iwnMHg+U9I=";
  };

  buildInputs = [ olm ];

  vendorSha256 = "sha256-aw+6vTqwGyqCWpl6G/dVrGS/z+0CNUBhaBzz1QTxcbM=";

  meta = with lib; {
    homepage = "https://github.com/mautrix/discord";
    description = " A Matrix-Discord puppeting bridge";
    license = licenses.agpl3Plus;
    maintainers = with maintainers; [ sumnerevans ];
  };
}
