{ pkgs, ... }:
let
  pycnite =
    with pkgs.python312Packages;
    buildPythonPackage rec {
      pname = "pycnite";
      version = "2024.7.31";
      pyproject = true;
      disabled = pythonOlder "3.8";
      src = fetchPypi {
        inherit pname version;
        hash = "sha256-USXxyVrvSiO5vsOzL652hz3NRjJPpo45wQ+oUuzeo0A=";
      };
      nativeBuildInputs = [
        setuptools
        wheel
      ];
    };
in
with pkgs.python312Packages;
buildPythonPackage rec {
  pname = "pytype";
  version = "2024.09.13";
  pyproject = true;
  disabled = pythonOlder "3.8";
  src = pkgs.fetchFromGitHub {
    owner = "google";
    repo = "pytype";
    rev = version;
    hash = "sha256-yQoY9937ExHQSIccLmAk2Kgezlb9N4tHEXALGB6faEA=";
    fetchSubmodules = true;
  };
  nativeBuildInputs = [
    ninja
    pybind11
    setuptools
    wheel
  ];
  propagatedBuildInputs = [
    pkgs.ninja
    attrs
    immutabledict
    importlab
    jinja2
    libcst
    msgspec
    networkx
    ninja
    pybind11
    pycnite
    pydot
    pylint
    tabulate
    toml
    typing-extensions
  ];
  patches = [
    # Un-pin networkx as in https://github.com/google/pytype/commit/7ae429f58690c219fabcf8b441c84cf009bc5ac2
    (pkgs.writeText "networkx-unpin.patch" ''
      diff --git a/requirements.txt b/requirements.txt
      index 330805f1..da5ab7f6 100644
      --- a/requirements.txt
      +++ b/requirements.txt
      @@ -7,7 +7,7 @@ immutabledict>=4.1.0
       jinja2>=3.1.2
       libcst>=1.0.1
       msgspec>=0.18.6
      -networkx<3.2
      +networkx>=2.8
       ninja>=1.10.0.post2
       pybind11>=2.10.1
       pycnite>=2024.07.31
      diff --git a/setup.cfg b/setup.cfg
      index 94f80ba5..cf0f21c4 100644
      --- a/setup.cfg
      +++ b/setup.cfg
      @@ -38,7 +38,7 @@ install_requires =
           jinja2>=3.1.2
           libcst>=1.0.1
           msgspec>=0.18.6
      -    networkx<3.2
      +    networkx>=2.8
           ninja>=1.10.0.post2
           pycnite>=2024.07.31
           pydot>=1.4.2
    '')
  ];
  pythonImportsCheck = [ "pytype" ];
  meta.mainProgram = "pytype";
}
