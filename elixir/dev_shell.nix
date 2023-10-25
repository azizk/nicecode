{ pkgs ? import <nixpkgs> { }, unstable ? import <unstable> { } }:

pkgs.mkShell {
  name = "dev-environment";

  buildInputs =
    let
      erlang_27 = unstable.beam.beamLib.callErlang
        (
          { mkDerivation }:
          mkDerivation {
            version = "27.3";
            sha256 = "sha256-ZT+d2altco156Bsk/n+Nk9P6Npg0zQIO+nY+I7CGtrw=";
          }
        )
        {
          parallelBuild = true;
          wxSupport = true;
          wxGTK = pkgs.wxGTK32;
          libGL = pkgs.libGL;
          libGLU = pkgs.libGLU;
          xorg = pkgs.xorg;
          autoconf = unstable.buildPackages.autoconf269;
          ex_docSupport = true;
          # exdocSupport = true;
          ex_doc = unstable.beam_nodocs.packages.erlang_27.ex_doc;
        };

      # For elixir-ls:
      beamPkgs_27 = pkgs.beam.packagesWith erlang_27;

      elixir_1_18_otp_27 = pkgs.beam.beamLib.callElixir
        (
          { mkDerivation }:
          mkDerivation {
            version = "1.18.3";
            sha256 = "sha256-jH+1+IBWHSTyqakGClkP1Q4O2FWbHx7kd7zn6YGCog0=";
            minimumOTPVersion = "27.0";
            escriptPath = "lib/elixir/scripts/generate_app.escript";
          }
        )
        {
          erlang = erlang_27;
          debugInfo = true;
        };

      elixir-ls =
        (pkgs.callPackage /home/work/src/mynixos/packages/elixir-ls.nix {
          elixir = elixir_1_18_otp_27;
          inherit (beamPkgs_27) fetchMixDeps mixRelease;
        });
    in
    [
      erlang_27
      elixir_1_18_otp_27
      elixir-ls
      # pkgs.awscli2
      # pkgs.bundler
      # pkgs.ruby
      # pkgs.postgresql_13
      # pkgs.esbuild
      # pkgs.dart-sass
    ];

  shellHook = ''
    echo "Started dev shell..."
  '';
}
