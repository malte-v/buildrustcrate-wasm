{
  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    mozilla = {
      url = "github:mozilla/nixpkgs-mozilla";
      flake = false;
    };
    nixpkgs.url = "github:NixOS/nixpkgs";
  };
  outputs = { flake-utils, mozilla, nixpkgs, ... }: flake-utils.lib.eachDefaultSystem (
    system:
      let
        overlay = final: prev:
          let
            rustChannel = prev.rustChannelOf {
              channel = "nightly";
              date = "2021-02-28";
              sha256 = "sha256-w/eod4+6q1Tf/Sf7fi1Jya0uNpdoG7R3TgpYavXNYss=";
            };
            rust = rustChannel.rust.override {
              extensions = [ "rust-src" ];
              targets = [ "wasm32-unknown-unknown" ];
            };
          in
            {
              rustc = rust;
              cargo = rust;
            };
        pkgs = import nixpkgs {
          inherit system;
          overlays = [
            (import "${mozilla}/rust-overlay.nix")
            overlay
          ];
        };
      in
        rec {
          defaultPackage = pkgs.buildRustCrate {
            crateName = "buildrustcrate-wasm";
            version = "0.1.0";
            src = ./.;
            type = [ "cdylib" "rlib" ];
            extraRustcOpts = [ "--target wasm32-unknown-unknown" ];
          };
          devShell = pkgs.mkShell {
            inputsFrom = [ defaultPackage ];
            buildInputs = with pkgs; [
              cargo-edit
            ];
          };
        }
  );
}
