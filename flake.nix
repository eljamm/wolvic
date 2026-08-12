{
  description = "Wolvic XR Browser dev environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config.android_sdk.accept_license = true;
          config.allowUnfree = true;
          overlays = [
            (final: prev: {
              etc2comp = final.callPackage ./nix/etc2comp/package.nix { };
              fxr-compressor = final.callPackage ./nix/compressor/package.nix { };
            })
          ];
        };

        # build-tools + NDK + CMake + platforms
        androidSdk = pkgs.androidenv.composeAndroidPackages {
          buildToolsVersions = [ "35.0.0" ];
          platformVersions = [ "35" ];
          includeNDK = true;
          ndkVersions = [ "27.0.12077973" ];
          cmakeVersions = [ "3.22.1" ];
        };

        androidSdkPath = "${androidSdk.androidsdk}/libexec/android-sdk";
      in
      {
        packages = {
          etc2comp = pkgs.etc2comp;
          fxr-compressor = pkgs.fxr-compressor;

          emulator = pkgs.androidenv.emulateApp {
            name = "emulate-wolvic-noapi";
            platformVersion = "35";
            abiVersion = "x86_64"; # armeabi-v7a, mips, x86, x86_64
            systemImageType = "default";
            androidEmulatorFlags = "-gpu guest";
            # TODO:
            # - launch app directly
            # - build apk with Nix?
            #app = ./app/build/outputs/apk/noapiX64GeckoGeneric/debug/Wolvic-noapi-x64-gecko-generic-debug.apk;
            #package = "com.igalia.wolvic";
            #activity = "VRBrowserActivity";
          };
        };

        devShells.default = pkgs.mkShell {
          name = "wolvic-dev";

          packages = with pkgs; [
            androidSdk.androidsdk
            fxr-compressor
            gitMinimal
            jdk17
            ninja
            python3
          ];

          env = {
            ANDROID_HOME = androidSdkPath;
            # ANDROID_SDK_ROOT = androidSdkPath;
            ANDROID_NDK_ROOT = "${androidSdkPath}/ndk-bundle";
            JAVA_HOME = "${pkgs.jdk17}";
          };

          shellHook =
            # bash
            ''
              export PROJECT_ROOT="$(git rev-parse --show-toplevel)"
              export GRADLE_USER_HOME="$PROJECT_ROOT/.gradle-home"; # avoid polluting ~/.gradle

              mkdir -p "$GRADLE_USER_HOME"

              cat <<-EOF
              ==================
               Wolvic dev shell
              ==================
               ANDROID_SDK_ROOT: $ANDROID_SDK_ROOT
               ANDROID_NDK_ROOT: $ANDROID_NDK_ROOT
               JAVA_HOME       : $JAVA_HOME
              ==================

              First, initialise submodules:
                git submodule update --init --recursive

              Then, run:
                ./gradlew <target>

              To see all available targets, run:
                ./gradlew tasks --all | grep '^app:assemble'
              EOF
            '';
        };
      }
    );
}
