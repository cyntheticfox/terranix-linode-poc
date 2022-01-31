# Terranix Linode POC Flake

The following is a Proof-of-Concept (POC) for using Linode with NixOS and Terraform, specifically using Terranix, and some patches to `nixpkgs` to provide a Linode-compatible image builder for upload.

This base configuration provides no ssh connectivity, and provisions the following:

- A Linode image (approx 2.5 GB) to the southeast region
- A Linode instance (Nanode 1 GB) to the southeast region

## Setup

Before anything, ensure you define the `LINODE_TOKEN` variable, either in the file, sourcing it from a Terraform sops configuration, or defining `TF_VAR_LINODE_TOKEN` in your environment:

```shell
export TF_VAR_LINODE_TOKEN=<YOUR_API_KEY_HERE>
```

It is also recommended that you change the default root password in the `config.nix` file, as this repository is meant to be publicly available. While the default configuration I provide does disable the OpenSSH server enabled by default, it is still best practice to change passwords when possible.

## Usage

Usage should be as simple as using `nix run .` to run the default application, which will build the image given the base configuration in `configuration/image-base.nix`.

### Sub-Command: Apply

You can explicitly apply the Terranix configuration with

```shell
nix run .#apply
```

You can then destroy the built configuration with

```shell
nix run .#destroy
```

## Important Notes

- This configuration is designed to run Terraform _locally_, not with Terraform Cloud, so _you_ are responsible for managing the `.tfstate` files. There is an explicit Git ignore for such.
- Terraform Cloud example pending
- Example with configuration through [tweag/terraform-nixos](https://github.com/tweag/terraform-nixos) pending

