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
      # To get the root of the project, use the following command as a workaround: $(git rev-parse --show-toplevel)
      # See https://github.com/NixOS/nix/issues/8034#issuecomment-3366842508 for more info
      hooks = let
        eslint-wrapper = pkgs.writeShellApplication {
          name = "eslint";
          runtimeInputs = [pkgs.pnpm];

          text = ''
            # Note that we use the pnpm version of eslint, which supports plugins
            pnpm --dir "$(git rev-parse --show-toplevel)"/frontend exec eslint  "''${@#frontend/}" --fix # Remove the "frontend/" prefix from filenames before passing to prettier, since prettier is being run in the /frontend directory anyways
          '';
        };

        prettier-wrapper = pkgs.writeShellApplication {
          name = "prettier";
          runtimeInputs = [pkgs.pnpm];

          text = ''
            # Note that we use the pnpm version of prettier, which supports plugins
            pnpm --dir "$(git rev-parse --show-toplevel)"/frontend exec prettier --write "''${@#frontend/}"
          '';
        };

        svelte-check-wrapper = pkgs.writeShellApplication {
          name = "svelte-check";
          runtimeInputs = [pkgs.pnpm];

          text = ''
            # Note that we use the pnpm version of svelte-check, which supports plugins
            pnpm --dir "$(git rev-parse --show-toplevel)"/frontend exec svelte-check "''${@#frontend/}"
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
              "json"
              "yaml"
              "svelte"
            ]
          })$";
        };

        svelte-check = {
          enable = true;
          name = "svelte-check";
          entry = "${lib.getExe svelte-check-wrapper}";

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
      # Install pre-commit hooks in the shell hook
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
