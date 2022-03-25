{ pkgs }:

pkgs.callPackage ./sqltoolsservice.nix { pkgs = pkgs; }
