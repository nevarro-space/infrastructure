{ lib, stdenv, fetchurl, gnutar, jdk11 }:
stdenv.mkDerivation rec {
  version = "9.8.0-6456";
  pname = "pc2";

  src = fetchurl {
    url = "https://github.com/pc2ccs/builds/releases/download/v${version}/pc2-${version}.tar.gz";
    hash = "sha256-04f3YGX18ioijdSd3ZvMb4jYOyCoMjZPimL+Kd+xt3Y=";
  };

  nativeBuildInputs = [ gnutar ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin $out/wti/bin

    # Install lib files
    cp -r lib $out

    # Install the WTI
    mkdir -p $out/wti/bin
    pushd projects
      tar -xvf WebTeamInterface-1.1-6456.tar.gz
      pushd WebTeamInterface-1.1
        cp -r WebContent $out/wti
        install -Dm755 WebTeamInterface-1.1.jar $out/wti
        substituteInPlace bin/pc2wti \
          --replace 'java' "${jdk11}/bin/java" \
          --replace 'WebTeamInterface' "$out/wti/WebTeamInterface"
        install -Dm755 bin/pc2wti $out/wti/bin
      popd
    popd

    files=bin/*
    for file in $files; do
      if [[ $file == *.bat ]]; then
        continue
      fi

      substituteInPlace "$file" --replace 'java' "${jdk11}/bin/java"
      install -Dm755 $file $out/bin
    done

    runHook postInstall
  '';

  meta = with lib; {
    description = "PC2 Contest Control System";
    homepage = "https://pc2ccs.github.io/";
    license = licenses.epl20;
    platforms = platforms.linux;
    maintainers = [ maintainers.sumnerevans ];
  };
}
