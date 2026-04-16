{
  description = "Devshell for this project";

  nixConfig = {
    extra-substituters = [
      "https://fenix.cachix.org"
    ];
    extra-trusted-public-keys = [
      "fenix.cachix.org-1:ecJhr+RdYEdcVgUkjruiYhjbBloIEGov7bos90cZi0Q="
    ];
  };

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    git-hooks = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    fenix = {
      url = "github:nix-community/fenix/monthly";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    ...
  } @ inputs: let
    system = "x86_64-linux";
    pkgs = import nixpkgs {
      inherit system;
      overlays = [inputs.fenix.overlays.default];
    };

    lib = pkgs.lib;

    rust-toolchain = pkgs.fenix.fromToolchainFile {
      file = ./hls-server/rust-toolchain.toml;
      sha256 = "sha256-AJ6LX/Q/Er9kS15bn9iflkUwcgYqRQxiOIL2ToVAXaU=";
    };

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

        prettier-svelte-wrapper = pkgs.writeShellApplication {
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
            pnpm --dir "$(git rev-parse --show-toplevel)"/frontend exec svelte-check
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

        prettier-svelte = {
          enable = true;
          name = "prettier-svelte";
          entry = "${lib.getExe prettier-svelte-wrapper}";

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
          pass_filenames = false;

          files = "^frontend/.*\\.(${
            builtins.concatStringsSep "|" [
              "js"
              "ts"
              "svelte"
            ]
          })$";
        };

        clippy = {
          enable = true;

          packageOverrides = {
            cargo = rust-toolchain;
            clippy = rust-toolchain;
          };

          settings = {
            allFeatures = true;
            denyWarnings = true;
            extraArgs = "--manifest-path hls-server/Cargo.toml";
          };
        };

        rustfmt = {
          enable = true;

          packageOverrides = {
            cargo = rust-toolchain;
            rustfmt = rust-toolchain;
          };

          settings = {
            check = true;
            manifest-path = "hls-server/Cargo.toml";
          };
        };

        check-toml.enable = true;
        taplo.enable = true;

        prettier = {
          enable = true;

          # prettier-svelte will handle files in frontend/
          excludes = ["^frontend/.*"];
        };

        markdownlint.enable = true;
      };
    };
  in {
    devShells.${system}.default = pkgs.mkShell {
      # Install pre-commit hooks in the shell hook
      inherit (pre-commit-check) shellHook;

      packages = with pkgs; [
        # MARKDOWN
        markdownlint-cli # Formatter

        # NIX
        nixd # LSP
        alejandra # Formatter

        # NODE
        nodejs_25
        pnpm

        # RUST
        rust-toolchain
        rust-analyzer-nightly
      ];
    };
  };
}
