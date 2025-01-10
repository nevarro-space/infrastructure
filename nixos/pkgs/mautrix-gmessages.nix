{
  lib,
  buildGoModule,
  fetchFromGitHub,
  olm,
  # This option enables the use of an experimental pure-Go implementation of
  # the Olm protocol instead of libolm for end-to-end encryption. Using goolm
  # is not recommended by the mautrix developers, but they are interested in
  # people trying it out in non-production-critical environments and reporting
  # any issues they run into.
  withGoolm ? false,
}:

buildGoModule {
  pname = "mautrix-gmessages";
  version = "0.6.0-unstable-2025-01-10";

  src = fetchFromGitHub {
    owner = "mautrix";
    repo = "whatsapp";
    rev = "4e55805eb2eadc05c80ac3b25f8f20d86c971be1";
    hash = "sha256-3S4aNoxK99iExhTJQAAAAAAAAAAAAAAA4cUgCBudyXI=";
  };

  buildInputs = lib.optional (!withGoolm) olm;
  tags = lib.optional withGoolm "goolm";

  vendorHash = "sha256-9iX+pzken+AAAAAAAAAAAAAAlCdpmu3UfR09ag3KSKs=";

  doCheck = false;

  meta = with lib; {
    homepage = "https://github.com/tulir/mautrix-gmessages";
    description = "A Matrix <-> Google Messages puppeting bridge ";
    license = licenses.agpl3Plus;
    maintainers = with maintainers; [
      sumnerevans
    ];
    mainProgram = "mautrix-gmessages";
  };
}
