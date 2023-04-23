{ lib, stdenv, fetchurl }:
stdenv.mkDerivation rec {
  version = "1.0";
  pname = "mineshspc2022";

  src = ./config;
  dontUnpack = true;

  installPhase = ''
    runHook preInstall

    cp -r $src $out

    runHook postInstall
  '';
}
