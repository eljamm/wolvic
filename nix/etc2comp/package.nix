{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "etc2comp";
  version = "0-unstable-2022-06-01";

  src = fetchFromGitHub {
    owner = "google";
    repo = "etc2comp";
    rev = "39422c1aa2f4889d636db5790af1d0be6ff3a226";
    hash = "sha256-mLr2Fsn9s9eWi71ljCll8c1hCk+dW6jCr7GG67ZTZ00=";
  };

  nativeBuildInputs = [
    cmake
  ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/{bin,lib,opt}
    cp EtcTool/EtcTool $out/bin/
    cp EtcLib/libEtcLib.a $out/lib/
    ln -s $out/bin/EtcTool $out/bin/etc2comp

    runHook postInstall
  '';

  env = {
    CMAKE_POLICY_VERSION_MINIMUM = "3.5";
  };

  meta = {
    description = "Texture to ETC2 compressor";
    homepage = "https://github.com/google/etc2comp";
    mainProgram = "etc2comp";
    license = lib.licenses.asl20;
    platforms = lib.platforms.all;
  };
})
