{
  description = "sqltoolsservice";

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

        dotnet = (import ./dotnet-exact.nix) { inherit pkgs; };

        cakeDepSource = pkgs.mkNugetSource {
          name = "cake-deps-nuget-source";
          description =
            "A Nuget source with the dependencies for teh Cake build of the STS";
          deps = [
            (pkgs.mkNugetDeps {
              name = "cake-deps-nuget-deps";
              nugetDeps = import ./deps.nix;
            })
          ];
        };

        sqlTS = buildDotnetModule {
          pname = "sqltoolsservice";
          #read from `packages/Directory.Build.props`, under `PackageVersion`:
          version = version;
          src = src;

          dotnet-sdk = dotnet.sdk;
          dotnet-runtime = dotnet.runtime;
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
            tree
            which
          ];

          # run-time dependencies
          buildInputs = [ ];

          patches = [
            ./0001-use_nuget_from_the_nix_store.patch

            # /build/source/Directory.Build.targets : error : Unable to find package Microsoft.Build.CentralPackageVersions. No packages exist with this id in source(s): Local Packages, nuget.org
            # (why doesn't nuget-to-nix include `Microsoft.Build.CentralPackageVersions`?)
            ./0002-skip-CentralPackageVersions-package.patch

            # https://github.com/microsoft/sqltoolsservice/issues/1173
            ./0003-stop-importing-from-private-feeds.patch

            /* Bug with "preview" nuget packages & nuget-to-nix?

               error NU1103: Unable to find a stable package Microsoft.SqlServer.DacFx with version  [/build/source/sqltoolsservice.sln]
               error NU1103:   - Found 1 version(s) in /nix/store/07g76wxd9n58c0ba7zk3bmr25yhffbcc-sqltoolsservice-nuget-source/lib [ Nearest version: 160.6057.0-preview ] [/build/source/sqltoolsservice.sln]

               https://stackoverflow.com/a/69926686/2014893
            */
            ./0005-allow-the-dacfx-package-to-be-found.patch

            # cake build tries to get on the internet?
            ./0006-bad-nuget-bad.patch

            # where are we up to in the log?
            ./0007-cake-bootstrapper-waypoints.patch
          ];

          # configurePhase = ...
          # good reference? https://github.com/NixOS/nixpkgs/blob/81eb599e8d662940f451aee1f6fcb3af24c1b655/pkgs/servers/jellyfin/default.nix#L73-L83

          buildPhase = ''
            cp ${./standardizeCase.sh} ./standardizeCase.sh
            patchShebangs ./
            ./standardizeCase.sh
            mkdir -p ./.tools
            ln -s ${nuget}/lib/dotnet/Nuget/nuget.exe ./.tools/nuget.exe
            #echo "buildPhase::restore"
            #dotnet restore --configfile ./nuget.config

            #echo "________________________"
            #echo "Content of HOME/.nuget :"
            #tree -phugD $HOME/.nuget

            #echo "________________________"
            #echo "Content of ./bin/nuget :"
            #tree -phugD  ./bin/nuget

            echo "buildPhase::scripts-restore"
            nuget restore ./scripts/packages.config -OutputDirectory $HOME/.nuget \
                -Source ${cakeDepSource}/lib -Source ./bin/nuget

            echo "buildPhase::build.sh"
            ./build.sh
          '';

          # installPhase is handled by `buildDotnetModule`

          #passthru = { exePath = "/bin/frink-cli.sh"; };

          system = system;
        };

      in {
        defaultPackage = sqlTS;
        packages.sqlTS = sqlTS;
        packages.src = src;
        devShell = pkgs.mkShell {
          name = "sqltoolsservice-nix-shell";

          buildInputs = [
            (pkgs.runCommand "fetch-deps" { preferLocalBuild = true; } ''
              install -D -m755 ${./fetch-deps.sh} $out/bin/fetch-deps
            '')
            dotnet.sdk
            nuget
            pkgs.nuget-to-nix
            pkgs.nixfmt
            pkgs.unzip
          ];

          shellHook = ''
            echo Dependencies present.
          '';
        };
      });
}
