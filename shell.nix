{ pkgs ? import <nixpkgs> { } }:
let
  dotnetCombined = with pkgs.dotnetCorePackages;
    combinePackages [ sdk_3_1 sdk_6_0_101 ];

  buildDotnet = attrs: pkgs.callPackage (import ./build-dotnet.nix attrs) { };
  buildAspNetCore = attrs: buildDotnet (attrs // { type = "aspnetcore"; });
  buildNetRuntime = attrs: buildDotnet (attrs // { type = "runtime"; });
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

in pkgs.mkShell {
  name = "sqltoolsservice-shell";

  buildInputs = with pkgs; [ dotnetCombined mono6 ];

  shellHook = ''
    echo Dependencies present.
  '';
}
