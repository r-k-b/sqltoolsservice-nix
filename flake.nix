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
            dotnetCombined
            silver-searcher
            mono6
            nuget
            nuget-to-nix
            which
          ];

          # run-time dependencies
          buildInputs = [ ];

          patches = [ ./0001-use_nuget_from_the_nix_store.patch ];

          # configurePhase = ...
          # good reference? https://github.com/NixOS/nixpkgs/blob/81eb599e8d662940f451aee1f6fcb3af24c1b655/pkgs/servers/jellyfin/default.nix#L73-L83

          buildPhase = ''
            patchShebangs ./
            ./standardizeCase.sh
            mkdir -p ./.tools
            ln -s ${nuget}/lib/dotnet/Nuget/nuget.exe ./.tools/nuget.exe
            git apply -v --directory ./ ${
              ./0001-use_nuget_from_the_nix_store.patch
            }
            git apply -v --directory ./ ${
              ./0003-stop-importing-from-private-feeds.patch
            }
            ./build.sh
          '';

          installPhase = ''
            mkdir -p $out/bin
            touch $out/bin fixme
            echo fixme
          '';

          #passthru = { exePath = "/bin/frink-cli.sh"; };

          system = system;
        };
        dotnetCombined = with pkgs.dotnetCorePackages;
          combinePackages [ sdk_3_1 sdk_6_0_101 ];

        buildDotnet = attrs:
          pkgs.callPackage (import ./build-dotnet.nix attrs) { };
        buildNetSdk = attrs: buildDotnet (attrs // { type = "sdk"; });
        sdk_6_0_101 = buildNetSdk {
          version = "6.0.101";
          sha512 = {
            x86_64-linux =
              "ca21345400bcaceadad6327345f5364e858059cfcbc1759f05d7df7701fec26f1ead297b6928afa01e46db6f84e50770c673146a10b9ff71e4c7f7bc76fbf709";
            aarch64-linux =
              "04cd89279f412ae6b11170d1724c6ac42bb5d4fae8352020a1f28511086dd6d6af2106dd48ebe3b39d312a21ee8925115de51979687a9161819a3a29e270a954";
            x86_64-darwin =
              "36fde8f0cc339a01134b87158ab922de27bb3005446d764c3efd26ccb67f8c5acc16102a4ecef85a402f46bf4dfc9bdc28063806bb2b4a4faf0def13277a9268";
            aarch64-darwin =
              "af76f778e5195c38a4b6b72f999dc934869cd7f00bbb7654313000fbbd90c8ac13b362058fc45e08501319e25d5081a46d08d923ec53496d891444cf51640cf5";
          };
        };

      in {
        defaultPackage = sqlTS;
        packages.sqlTS = sqlTS;
        packages.src = src;
        #devShell = import ./shell.nix { inherit pkgs; };
      });
}
