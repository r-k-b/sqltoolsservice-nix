let
  pkgs = import <nixpkgs> { };

  dotnetCombined = with pkgs.dotnetCorePackages;
    combinePackages [ sdk_6_0 pkgs.dotnet-sdk ];

in pkgs.mkShell {
  name = "sqltoolsservice-shell";

  buildInputs = with pkgs; [ dotnetCombined ];
}
