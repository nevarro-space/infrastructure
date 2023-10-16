{ lib, fetchFromGitHub, buildGoModule, olm }:

buildGoModule rec {
  pname = "standupbot";
  version = "unstable-2023-06-02";

  src = fetchFromGitHub {
    owner = "beeper";
    repo = "standupbot";
    rev = "885677b757df4febdee9fa4fee9a6c6b4e3eb8d8";
    hash = "sha256-pa0k3ZvAWC+/woH2/mLYLaYWijO+lIFe5Ht5/bo3cBU=";
  };

  buildInputs = [ olm ];

  vendorSha256 = "sha256-X5D38xyde8zwYZg4RIKbz9v5mFU7inKLMPI9iVbifYI=";

  meta = with lib; {
    homepage = "https://github.com/beeper/standupbot";
    description = "A Matrix bot for helping with standup posts";
    license = licenses.agpl3Plus;
    maintainers = with maintainers; [ sumnerevans ];
  };
}
