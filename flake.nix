{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:houstdav000/nixpkgs/feature/linode-image";
    flake-utils.url = "github:numtide/flake-utils";

    terranix = {
      url = "github:terranix/terranix";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-utils.follows = "flake-utils";
      };
    };

    nixos-generators = {
      url = "github:houstdav000/nixos-generators/feature/linode";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Utilities
    pre-commit-hooks.url = "github:cachix/pre-commit-hooks.nix";
  };

  outputs = { self, ... }@inputs:
    with inputs;

    let
      pkgs = nixpkgs.legacyPackages.x86_64-linux;
      inherit (pkgs) terraform;
      terraformConfiguration = terranix.lib.terranixConfiguration {
        system = "x86_64-linux";
        modules = [
          {
            config._module.args = {
              inherit self pkgs;
              inherit (self) inputs outputs;
            };
          }
          ./config.nix
        ];
      };
    in
    {
      apps.x86_64-linux = {
        default = self.apps.x86_64-linux.apply;

        apply = {
          type = "app";
          program = builtins.toString (pkgs.writers.writeBash "apply" ''
            # Remove old config.tf.json
            if [[ -e config.tf.json ]]; then
              rm -f config.tf.json
            fi

            # Run the apply
            cp ${terraformConfiguration} config.tf.json \
              && ${terraform}/bin/terraform init \
              && ${terraform}/bin/terraform apply -auto-approve

            # Remove old config.tf.json and if successful
            if [[ $? && -e config.tf.json ]]; then
              rm -f config.tf.json
            fi
          '');
        };

        destroy = {
          type = "app";
          program = builtins.toString (pkgs.writers.writeBash "destroy" ''
            # Remove old config.tf.json
            if [[ -e config.tf.json ]]; then
              rm -f config.tf.json
            fi

            # Run the destroy
            cp ${terraformConfiguration} config.tf.json \
              && ${terraform}/bin/terraform init \
              && ${terraform}/bin/terraform destroy

            # Remove old config.tf.json and if successful
            if [[ $? && -e config.tf.json ]]; then
              rm -f config.tf.json
            fi
          '');
        };
      };

      defaultApp.x86_64-linux = self.apps.x86_64-linux.apply;

      devShells.x86_64-linux.default = pkgs.mkShell {
        inherit (self.checks.x86_64-linux.pre-commit-check) shellHook;

        nativeBuildInputs = with pkgs; [
          terraform

          # Formatting
          nixpkgs-fmt
          statix
        ];
      };

      devShell.x86_64-linux = self.devShells.x86_64-linux.default;

      packages.x86_64-linux.linode = nixos-generators.nixosGenerate {
        pkgs = nixpkgs.legacyPackages.x86_64-linux;
        modules = [ ./config/image-base.nix ];
        format = "linode";
      };

      checks.x86_64-linux = {
        pre-commit-check = pre-commit-hooks.lib.x86_64-linux.run {
          src = ./.;
          hooks = {
            nixpkgs-fmt.enable = true;
            statix.enable = true;
          };
        };

        validTerraform = pkgs.writers.writeBash "validate" ''
          # Remove old config.tf.json
          if [[ -e config.tf.json ]]; then
            rm -f config.tf.json
          fi

          # Run the destroy
          cp ${terraformConfiguration} config.tf.json \
            && ${terraform}/bin/terraform init \
            && ${terraform}/bin/terraform validate

          # Remove old config.tf.json and if successful
          if [[ $? && -e config.tf.json ]]; then
            rm -f config.tf.json
          fi
        '';
      };
    };
}
