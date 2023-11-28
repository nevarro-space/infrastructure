{ lib, fetchFromGitHub, python3 }:

with python3.pkgs;

buildPythonPackage rec {
  pname = "linkedin-messaging";
  version = "0.6.0";
  format = "pyproject";

  src = fetchFromGitHub {
    owner = "beeper";
    repo = "linkedin-messaging-api";
    rev = "v${version}";
    hash = "sha256-Bn/yxv+RZrBtvpyotWhEY2HafIRTaWxiTexP4AVTJ0A=";
  };

  nativeBuildInputs = [ python3.pkgs.flit-core ];

  propagatedBuildInputs = [ aiohttp beautifulsoup4 dataclasses-json ];

  pythonImportsCheck = [ "linkedin_messaging" ];

  meta = with lib; {
    description = "An unofficial API for interacting with LinkedIn Messaging.";
    homepage = "https://github.com/sumnerevans/linkedin-messaging-api";
    license = licenses.asl20;
    maintainers = [ maintainers.sumnerevans ];
  };
}
