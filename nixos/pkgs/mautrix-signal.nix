{ pkgs, lib, buildGoModule, fetchFromGitHub, olm }:
let libsignal-ffi = pkgs.callPackage ./libsignal-ffi { };
in buildGoModule {
  pname = "mautrix-signal";
  # mautrix-signal's latest released version v0.4.3 still uses the Python codebase
  # which is broken for new devices, see https://github.com/mautrix/signal/issues/388.
  # The new Go version fixes this by using the official libsignal as a library and
  # can be upgraded to directly from the Python version.
  version = "unstable-2023-12-30";

  src = fetchFromGitHub {
    owner = "mautrix";
    repo = "signal";
    rev = "5558469743463c3034b0d005f7d6b5592879b69d";
    hash = "sha256-BN689DzW1sxJ5mTUtKsDFMQG4kGgAks8fOhXhNLrCoM=";
  };

  buildInputs = [
    olm
    # must match the version used in https://github.com/mautrix/signal/tree/main/pkg/libsignalgo
    # see https://github.com/mautrix/signal/issues/401
    libsignal-ffi
  ];

  vendorHash = "sha256-k26gjsfB0iXZCKKDWgpfPXn9u+IayipiCElTZ1XCJFM=";

  doCheck = false;

  meta = with lib; {
    homepage = "https://github.com/mautrix/signal";
    description = "A Matrix-Signal puppeting bridge";
    license = licenses.agpl3Plus;
    maintainers = with maintainers; [ expipiplus1 niklaskorz ma27 ];
    mainProgram = "mautrix-signal";
  };
}
