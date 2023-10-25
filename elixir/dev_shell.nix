{ pkgs ? import <nixpkgs> { } }:

pkgs.mkShell {
  name = "dev-environment";

  buildInputs = with pkgs;
    let
      # Check example: https://github.com/cassandracomar/nix-config/blob/main/users/base/elixir.nix
      erlang_26 = erlangR25.override {
        version = "26.1.2";
        # nix-prefetch-url --unpack https://github.com/erlang/otp/archive/OTP-26.1.2.tar.gz
        sha256 = "0h7v9py78c66nn56b7xrs7lcah21vixxyw6d4f4p5z7k1rvcn4kv";
        javacSupport = false;
        odbcSupport = false;
        configureFlags = [ "--with-ssl=${lib.getOutput "out" openssl}" ]
          ++ [ "--with-ssl-incl=${lib.getDev openssl}" ];
      };

      # NixOS pkg:
      # https://github.com/NixOS/nixpkgs/blob/nixos-23.05/pkgs/development/interpreters/elixir/1.15.nix

      # Flake:
      # https://github.com/NobbZ/ledgex/blob/0944e7c4877153dec7f361fd597b90568be14bec/flake.nix

      # Nix Beam Flakes
      # https://github.com/shanesveller/nix-beam-flakes

      beamPkg = beam.packagesWith erlang_26;

      elixir_1_15 = beamPkg.elixir_1_15.override {
        version = "1.15.7";
        # nix-prefetch-url --unpack https://github.com/elixir-lang/elixir/archive/refs/tags/v1.15.7.tar.gz
        sha256 = "0yfp16fm8v0796f1rf1m2r0m2nmgj3qr7478483yp1x5rk4xjrz8";
      };
    in
    [
      awscli2
      bundler
      ruby
      erlang_26
      elixir_1_15
      postgresql_13
      # esbuild
      # dart-sass
    ];

  shellHook = ''
    echo "Started dev shell..."
  '';
}
