{
  lib,
  stdenvNoCC,
  fetchurl,
  makeWrapper,
  autoPatchelfHook,
  nodejs,
  git,
  ripgrep,
  fd,
  zlib,
  stdenv,
  system,
  version,
  asset,
}:
let
  isLinux = lib.hasSuffix "-linux" system;

  runtimeBins = lib.makeBinPath [
    nodejs
    git
    ripgrep
    fd
  ];

  runtimeLibs = lib.makeLibraryPath [
    stdenv.cc.cc.lib
    zlib
  ];
in
stdenvNoCC.mkDerivation {
  pname = "pi-coding-agent";
  inherit version;

  src = fetchurl { inherit (asset) url hash; };

  sourceRoot = "pi";

  nativeBuildInputs = [ makeWrapper ];

  buildInputs = lib.optionals isLinux [
    stdenv.cc.cc.lib
    zlib
  ];

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/libexec/pi $out/bin
    cp -r . $out/libexec/pi/
    chmod +x $out/libexec/pi/pi

    ${if isLinux then ''
      makeWrapper $out/libexec/pi/pi $out/bin/pi \
        --prefix PATH : "${runtimeBins}" \
        --run 'export NPM_CONFIG_PREFIX="''${NPM_CONFIG_PREFIX:-$HOME/.local/share/pi/npm-prefix}"' \
        --run 'mkdir -p "$NPM_CONFIG_PREFIX"'
    '' else ''
      makeWrapper $out/libexec/pi/pi $out/bin/pi \
        --prefix PATH : "${runtimeBins}" \
        --run 'export NPM_CONFIG_PREFIX="''${NPM_CONFIG_PREFIX:-$HOME/.local/share/pi/npm-prefix}"' \
        --run 'mkdir -p "$NPM_CONFIG_PREFIX"'
    ''}

    runHook postInstall
  '';

  meta = {
    description = "Pi - a minimal terminal coding harness (prebuilt)";
    homepage = "https://github.com/earendil-works/pi";
    license = lib.licenses.mit;
    mainProgram = "pi";
    platforms = [
      "aarch64-darwin" "x86_64-darwin"
      "aarch64-linux" "x86_64-linux"
    ];
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
}
