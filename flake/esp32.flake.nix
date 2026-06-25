{
  description = "ESP32 dev";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    esp-dev.url = "github:mirrexagon/nixpkgs-esp-dev";
  };

  outputs = {
    nixpkgs,
    esp-dev,
    ...
  }: let
    system = "x86_64-linux";
    pkgs = import nixpkgs {inherit system;};
  in {
    devShells.${system}.default = pkgs.mkShell {
      inputsFrom = [
        esp-dev.devShells.${system}.esp-idf-full
      ];

      shellHook = ''
        export IDF_TARGET=esp32
      '';
    };
  };
}
