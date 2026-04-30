{
  lib,
  buildNpmPackage,
  importNpmLock,
  makeWrapper,
  node-gyp,
  pkg-config,
  etc2comp,
  vips,
}:

let
  sourceRoot = ../../tools/compressor/.;
in

buildNpmPackage (finalAttrs: {
  pname = "fxr-compressor";
  version = "1.0.0";

  src = sourceRoot;

  postPatch = ''
    substituteInPlace gulpfile.js \
      --replace-fail \
        "assetsPath = '../../app/src/uncompressed_assets'" \
        "assetsPath = (process.env.PROJECT_ROOT || '../..') + '/app/src/uncompressed_assets'"
  '';

  npmDeps = importNpmLock { npmRoot = sourceRoot; };
  npmConfigHook = importNpmLock.npmConfigHook;

  # gulp is both a peerDependency and devDependency; pruning
  # devDependencies removes it, but the CLI needs it at runtime.
  dontNpmPrune = true;

  npmPackFlags = [ "--ignore-scripts" ];
  NODE_OPTIONS = "--openssl-legacy-provider";

  nativeBuildInputs = [
    makeWrapper
    node-gyp # for building node_modules/sharp from source
    pkg-config
  ];

  buildInputs = [
    etc2comp
    vips # or it will try to download from the Internet
  ];

  postFixup = ''
    makeWrapper \
      $out/lib/node_modules/fxr-compressor/node_modules/.bin/gulp \
      $out/bin/compress \
        --chdir "$out/lib/node_modules/fxr-compressor" \
        --add-flags "compress" \
        --set NODE_PATH "$out/lib/node_modules/fxr-compressor/node_modules"
  '';

  env = {
    SHARP_FORCE_GLOBAL_LIBVIPS = 1;
  };

  meta = {
    mainPackage = "compress";
  };
})
