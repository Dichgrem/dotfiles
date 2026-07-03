{
  description = "Android Compose development environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    android-nixpkgs = {
      url = "github:tadfisher/android-nixpkgs/stable";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
    android-nixpkgs,
  }:
    flake-utils.lib.eachDefaultSystem (
      system: let
        pkgs = import nixpkgs {
          inherit system;
        };

        android-sdk = android-nixpkgs.sdk.${system} (sdkPkgs:
          with sdkPkgs; [
            cmdline-tools-latest
            platform-tools
            # build-tools
            build-tools-34-0-0
            build-tools-35-0-0
            build-tools-36-0-0
            # SDK
            platforms-android-36
            platforms-android-35
            platforms-android-34
            platforms-android-33
          ]);
      in {
        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            # dart
            # kotlin
            # flutter
            # jdk17
            apksigner
            android-sdk
            gradle
          ];

          shellHook = ''
            # Android SDK env
            export ANDROID_HOME="${android-sdk}/share/android-sdk"
            export ANDROID_SDK_ROOT="$ANDROID_HOME"
            export PATH="$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$ANDROID_HOME/emulator:$PATH"

            # Java env
            export JAVA_HOME="${pkgs.jdk17}"

            # Gradle setting
            export GRADLE_USER_HOME="$PWD/.gradle"
            export GRADLE_OPTS="-Dorg.gradle.daemon=true -Dorg.gradle.parallel=true"

            # Gradle problem
            export GRADLE_OPTS="$GRADLE_OPTS -Dorg.gradle.project.android.aapt2FromMavenOverride=$ANDROID_HOME/build-tools/34.0.0/aapt2"

            # Release Key
            export KEYSTORE_FILE="$HOME/.android/jetlagged-release.keystore"
            export KEY_ALIAS="jetlagged"
            export KEYSTORE_PASSWORD="$(secret-tool lookup name android_keystore_password)"
            export KEY_PASSWORD="$(secret-tool lookup name android_key_password)"

            echo "Android Compose environment OK!"
            echo ""
            echo "SDK: $ANDROID_HOME"
            echo "Java: $(java -version 2>&1 | head -n 1)"
            echo "Gradle: $(gradle --version | grep Gradle)"
          '';
        };
      }
    );
}
