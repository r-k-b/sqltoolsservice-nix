{
  description =
    "SQL Tools API service that provides SQL Server data management capabilities.";

  inputs.flake-utils.url = "github:numtide/flake-utils";

  inputs.source = {
    url = "github:Microsoft/sqltoolsservice";
    flake = false;
  };

  outputs = { self, nixpkgs, flake-utils, source }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        inherit (pkgs) lib callPackage stdenv;

        sqltoolsservice = stdenv.mkDerivation {
          pname = "sqltoolservice";
          version = "fixme";

          src = source;

          nativeBuildInputs = with pkgs; [ rsync makeWrapper ];

          phases = "unpackPhase fixupPhase";

          unpackPhase = ''
            # what folder are we expected to be in right now?
            # is it different between nix-shell and nix-build?
            echo pwd=$PWD
            touch ./THIS_CAME_FROM_OUR_UNPACKPHASE

            mkdir -p $out/bin
            ls > $out/ls
          '';
          #
          #          fixupPhase = ''
          #            makeWrapper ${p3p.python.interpreter} $out/bin/mssqlscripter \
          #              --set PYTHONPATH "$PYTHONPATH:$out" \
          #              --add-flags "-O $out/mssqlscripter/main.py"
          #
          #            fix_sqltoolsservice()
          #            {
          #              mv $out/${sqlToolsServicePath}/$1 $out/${sqlToolsServicePath}/$1_old
          #              patchelf \
          #                --set-interpreter "${stdenv.cc.bintools.dynamicLinker}" \
          #                $out/${sqlToolsServicePath}/$1_old
          #              makeWrapper \
          #                $out/${sqlToolsServicePath}/$1_old \
          #                $out/${sqlToolsServicePath}/$1 \
          #                --set LD_LIBRARY_PATH ${sqlToolsServiceRpath}
          #            }
          #            fix_sqltoolsservice MicrosoftSqlToolsServiceLayer
          #
          #            # not required for mssql-scripter? only azuredatastudio?
          #            #fix_sqltoolsservice MicrosoftSqlToolsCredentials
          #            #fix_sqltoolsservice SqlToolsResourceProviderService
          #
          #
          #            # do we need to set interpreter/cc/something like this? (copied from the azuredatastudio example)"
          #            #patchelf \
          #            #  --set-interpreter "${stdenv.cc.bintools.dynamicLinker}" \
          #            #  ${targetPath}/${edition}
          #
          #            # makeWrapper \
          #            #   ${targetPath}/bin/${edition} \
          #            #   $out/bin/foo \
          #            #   --set LD_LIBRARY_PATH ${rpath}
          #          '';

          meta = {
            homepage = "https://github.com/Microsoft/sqltoolsservice";
            description =
              "SQL Tools API service that provides SQL Server data management capabilities.";
            license = lib.licenses.mit;
          };
        };
      in { defaultPackage = sqltoolsservice; });
}
