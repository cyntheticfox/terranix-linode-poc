{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/release-22.11";
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

  outputs = { self, flake-utils, nixpkgs, nixos-generators, pre-commit-hooks, terranix }:
    nixpkgs.lib.recursiveUpdate
      (flake-utils.lib.eachDefaultSystem
        (system:
          let
            pkgs = nixpkgs.legacyPackages."${system}";
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
            apps = {
              default = self.apps."${system}".apply;

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

            devShells.default = pkgs.mkShell {
              inherit (self.checks."${system}".pre-commit-check) shellHook;

              nativeBuildInputs = with pkgs; [
                terraform

                # Formatting
                nixpkgs-fmt
                statix
              ];
            };

            checks = {
              pre-commit-check = pre-commit-hooks.lib."${system}".run {
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
          }))
      (
        let
          system = "x86_64-linux";
        in
        {
          packages."${system}".linode = nixos-generators.nixosGenerate {
            pkgs = nixpkgs.legacyPackages."${system}";
            modules = [ ./config/image-base.nix ];
            format = "linode";
          };
        }
      );
}
