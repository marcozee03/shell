{
  description = "Desktop shell for Uva dots";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    quickshell = {
      url = "git+https://git.outfoxxed.me/outfoxxed/quickshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    uva-cli = {
      url = "github:uva-dots/cli";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.uva-shell.follows = "";
    };
  };

  outputs = {
    self,
    nixpkgs,
    ...
  } @ inputs: let
    forAllSystems = fn:
      nixpkgs.lib.genAttrs nixpkgs.lib.platforms.linux (
        system: fn nixpkgs.legacyPackages.${system}
      );
  in {
    formatter = forAllSystems (pkgs: pkgs.alejandra);

    packages = forAllSystems (pkgs: rec {
      uva-shell = pkgs.callPackage ./nix {
        rev = self.rev or self.dirtyRev;
        stdenv = pkgs.clangStdenv;
        quickshell = inputs.quickshell.packages.${pkgs.system}.default.override {
          withX11 = false;
          withI3 = false;
        };
        app2unit = pkgs.callPackage ./nix/app2unit.nix {inherit pkgs;};
        uva-cli = inputs.uva-cli.packages.${pkgs.system}.default;
      };
      with-cli = uva-shell.override {withCli = true;};
      debug = uva-shell.override {debug = true;};
      default = uva-shell;
    });

    devShells = forAllSystems (pkgs: {
      default = let
        shell = self.packages.${pkgs.system}.uva-shell;
      in
        pkgs.mkShell.override {stdenv = shell.stdenv;} {
          inputsFrom = [shell shell.plugin shell.extras];
          packages = with pkgs; [material-symbols rubik nerd-fonts.caskaydia-cove];
          UVA_XKB_RULES_PATH = "${pkgs.xkeyboard-config}/share/xkeyboard-config-2/rules/base.lst";
        };
    });

    homeManagerModules.default = import ./nix/hm-module.nix self;
  };
}
