{ lib, fetchFromGitHub, buildGoModule, olm }:

buildGoModule rec {
  pname = "standupbot";
  version = "unstable-2023-05-11";

  src = fetchFromGitHub {
    owner = "beeper";
    repo = "standupbot";
    rev = "491d6451b448f821a1bb0e0bb62ceeaf20a7ccf8";
    sha256 = "sha256-xHB5euBeNmvF1igSR+9FUYuucX8JKZaI6xgU5ZDjXnc=";
  };

  buildInputs = [ olm ];

  vendorSha256 = "sha256-fJOoqdMjZC8BZl4/gyQ0qShI2MaBD9uXBK3k4JKvHc0=";

  meta = with lib; {
    homepage = "https://github.com/beeper/standupbot";
    description = "A Matrix bot for helping with standup posts";
    license = licenses.agpl3Plus;
    maintainers = with maintainers; [ sumnerevans ];
  };
}
