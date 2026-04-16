{
  description = "Devshell for this project";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    git-hooks = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    ...
  } @ inputs: let
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
    lib = pkgs.lib;

    pre-commit-check = inputs.git-hooks.lib.${system}.run {
      src = ./.;

      # GIT HOOKS GO HERE
      # See https://devenv.sh/git-hooks/ for how to configure hooks
      hooks = let
        eslint-wrapper = pkgs.writeShellApplication {
          name = "eslint";
          runtimeInputs = [pkgs.pnpm];

          text = ''
            # Note that we use the pnpm version of eslint, which supports plugins
            pnpm --dir "$(git rev-parse --show-toplevel)"/frontend exec eslint . --fix
          '';
        };

        prettier-wrapper = pkgs.writeShellApplication {
          name = "eslint";
          runtimeInputs = [pkgs.pnpm];

          text = ''
            # Note that we use the pnpm version of eslint, which supports plugins
            pnpm --dir "$(git rev-parse --show-toplevel)"/frontend exec prettier --write .
          '';
        };
      in {
        alejandra.enable = true;

        eslint = {
          enable = true;
          name = "eslint";
          entry = "${lib.getExe eslint-wrapper}";

          files = "^frontend/.*\\.(${
            builtins.concatStringsSep "|" [
              "js"
              "ts"
              "svelte"
            ]
          })$";
        };

        prettier = {
          enable = true;
          name = "prettier";
          entry = "${lib.getExe prettier-wrapper}";

          files = "^frontend/.*\\.(${
            builtins.concatStringsSep "|" [
              "js"
              "ts"
              "svelte"
            ]
          })$";
        };
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
