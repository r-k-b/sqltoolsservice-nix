{
  description = "phdsysnet";

  inputs = { flake-utils.url = "github:numtide/flake-utils"; };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          system = system;
          config = { allowUnfree = true; };
        };

        version = "3.0.0-release.212";

        src = fetchFromGitHub {
          owner = "microsoft";
          repo = "sqltoolsservice";
          rev = "v${version}";
          sha256 = "sha256-NFv4CgpfZeqtUN5MvTPZfz8kibvvNTOxrEkl8P3W42M=";
        };

        inherit (pkgs) lib buildDotnetModule callPackage fetchFromGitHub stdenv;

        nuget = pkgs.dotnetPackages.Nuget;

        sqlTS = buildDotnetModule {
          pname = "sqltoolsservice";
          #read from `packages/Directory.Build.props`, under `PackageVersion`:
          version = version;
          src = src;

          dotnet-sdk = dotnetCombined;
          dotnet-runtime = runtime_6_0_101;
          projectFile = "sqltoolsservice.sln";
          nugetDeps = ./deps.nix;
          # To update or recreate deps.nix, see `./fetch-deps.sh`.
          # For more general info about packaging .Net apps, see:
          # <https://github.com/NixOS/nixpkgs/blob/master/doc/languages-frameworks/dotnet.section.md>

          meta = with lib; {
            description =
              "SQL Tools API service that provides SQL Server data management capabilities.";
            license = licenses.mit;

            # ???
            #platforms = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" ];
          };

          # build-time dependencies
          nativeBuildInputs = with pkgs; [
            bash
            coreutils
            curl
            silver-searcher
            mono6
            nuget
            nuget-to-nix
            which
          ];

          # run-time dependencies
          buildInputs = [ ];

          patches = [
            ./0001-use_nuget_from_the_nix_store.patch

            # don't need 0002, as we have the exact SDK version.

            # https://github.com/microsoft/sqltoolsservice/issues/1173
            ./0003-stop-importing-from-private-feeds.patch

            /* The build errors out when it tries to find the packages for
               other platforms. Is there some way to make nuget-to-nix include
               those packages?
            */
            ./0004-dont-bother-with-other-target-runtimes.patch
          ];

          # configurePhase = ...
          # good reference? https://github.com/NixOS/nixpkgs/blob/81eb599e8d662940f451aee1f6fcb3af24c1b655/pkgs/servers/jellyfin/default.nix#L73-L83

          buildPhase = ''
            patchShebangs ./
            ${./standardizeCase.sh}
            mkdir -p ./.tools
            ln -s ${nuget}/lib/dotnet/Nuget/nuget.exe ./.tools/nuget.exe
            ./build.sh
          '';

          installPhase = ''
            mkdir -p $out/bin
            touch $out/bin fixme
            echo fixme
            exit 42
          '';

          #passthru = { exePath = "/bin/frink-cli.sh"; };

          system = system;
        };

        dotnetCombined = with pkgs.dotnetCorePackages;
          combinePackages [ sdk_3_1 sdk_6_0_101 ];

        buildDotnet = attrs:
          pkgs.callPackage (import ./build-dotnet.nix attrs) { };
        buildNetRuntime = attrs: buildDotnet (attrs // { type = "runtime"; });
        buildNetSdk = attrs: buildDotnet (attrs // { type = "sdk"; });
        # manually dig around for the urls at <https://dotnet.microsoft.com/en-us/download/dotnet>
        runtime_6_0_101 = buildNetRuntime {
          version = "6.0.101";
          srcs = {
            x86_64-linux = {
              url =
                "https://download.visualstudio.microsoft.com/download/pr/be8a513c-f3bb-4fbd-b382-6596cf0d67b5/968e205c44eabd205b8ea98be250b880/dotnet-runtime-6.0.1-linux-x64.tar.gz";
              sha512 =
                "sha512-KjFujLogd4tAm48qOBA0jigF81r62KunemfE5rssIJHmC8Np3yJVS7FFpfrQxQ4gs501C5ioW9M1ZgNKESMNpw==";
            };
            #aarch64-linux = {
            #  url =
            #    "https://download.visualstudio.microsoft.com/download/pr/89b5d16e-cb5e-4e6c-90f6-7332e93d20ae/7a0146aa4fc59154a3256c5196a622c7/dotnet-runtime-6.0.101-linux-arm64.tar.gz";
            #  sha512 =
            #    "000000000000000000000000c3de1a11ce574cc843cde429850db0996c7df403dfa348a277f1af96f13fec718ae77f3be75379ed3829b027e561564ff22c7258";
            #};
            #x86_64-darwin = {
            #  url =
            #    "https://download.visualstudio.microsoft.com/download/pr/1f354e35-ff3f-4de7-b6be-f5001b7c3976/b7c8814ab28a6f00f063440e63903105/dotnet-runtime-6.0.101-osx-x64.tar.gz";
            #  sha512 =
            #    "000000000000000000000000bb45726b78e87d4f554fd30123cc8d9568b5341cc5bba16c8e4c85537ec4798d7e4d7f2f11701d2045b124f1b36bca75d80458e8";
            #};
            #aarch64-darwin = {
            #  url =
            #    "https://download.visualstudio.microsoft.com/download/pr/03047609-269e-4ca6-bf2e-406c496b27e3/3b19ad4d3fbc5d9a92f436db13e9e3d1/dotnet-runtime-6.0.101-osx-arm64.tar.gz";
            #  sha512 =
            #    "0000000000000000000000006dfba28a626850c40f93a0debe46c54f0c0b39526f4118d5b2bcf0307efeba0bc2656a92187a685400095ae078227698a0aabfb3";
            #};
          };
        };
        sdk_6_0_101 = buildNetSdk {
          version = "6.0.101";
          srcs = {
            x86_64-linux = {
              url =
                "https://download.visualstudio.microsoft.com/download/pr/ede8a287-3d61-4988-a356-32ff9129079e/bdb47b6b510ed0c4f0b132f7f4ad9d5a/dotnet-sdk-6.0.101-linux-x64.tar.gz";
              sha512 =
                "sha512-yiE0VAC8rOra1jJzRfU2ToWAWc/LwXWfBdffdwH+wm8erSl7aSivoB5G22+E5QdwxnMUahC5/3Hkx/e8dvv3CQ==";
            };
            #aarch64-linux = {
            #  url =
            #    "https://download.visualstudio.microsoft.com/download/pr/33c6e1e3-e81f-44e8-9de8-91934fba3c94/9105f95a9e37cda6bd0c33651be2b90a/dotnet-sdk-6.0.101-linux-arm64.tar.gz";
            #  sha512 =
            #    "0000000000000000000e4df0e842063642394fd22fe2a8620371171c8207ae6a4a72c8c54fc6af5b6b053be25cf9c09a74504f08b963e5bd84544619aed9afc2";
            #};
            #x86_64-darwin = {
            #  url =
            #    "https://download.visualstudio.microsoft.com/download/pr/cecaa095-3254-4987-b105-6bb9b594a89c/df29881aea827565a96d5e47dc337749/dotnet-sdk-6.0.101-osx-x64.tar.gz";
            #  sha512 =
            #    "0000000000000000000cd95083aa00ec7b266618770e164d6460d0cf781b3643a7365ef35232140c83b588f7aa4e2d7e5f5b6d627f1851b2d0ec197172f9fb4d";
            #};
            #aarch64-darwin = {
            #  url =
            #    "https://download.visualstudio.microsoft.com/download/pr/628be5e6-7fc7-42b6-99c9-ea46fbcc3d14/d94bb4198af2d5013c75b1c70751ec8f/dotnet-sdk-6.0.101-osx-arm64.tar.gz";
            #  sha512 =
            #    "0000000000000000000885548983889dcffd26a5c0ac935b497b290ae99920386f3929cebfbef9bb22f644a207ba329cf8b90ffe7bbb49d1d99d0d8a05ce50c9";
            #};
          };
        };

      in {
        defaultPackage = sqlTS;
        packages.sqlTS = sqlTS;
        packages.src = src;
        #devShell = import ./shell.nix { inherit pkgs; };
      });
}
