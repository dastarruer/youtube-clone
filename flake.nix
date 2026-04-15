{
  description = "Devshell for this project";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    git-hooks.url = "github:cachix/git-hooks.nix";
  };

  outputs = {
    self,
    nixpkgs,
    ...
  } @ inputs: let
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};

    pre-commit-check = inputs.git-hooks.lib.${system}.run {
      src = ./.;

      # GIT HOOKS GO HERE
      # See https://devenv.sh/git-hooks/ for how to configure hooks
      hooks = {
        alejandra.enable = true;
      };
    };
  in {
    devShells.${system}.default = pkgs.mkShell {
      inherit (pre-commit-check) shellHook;

      packages = with pkgs; [
        # NIX
        nixd # LSP
        alejandra # Formatter

        # NODE
        nodejs_25
        pnpm
      ];
    };
  };
}
