{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    systems.url = "github:nix-systems/default";
    transpire.url = "github:oliver-ni/transpire";
    transpire.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { nixpkgs, systems, transpire, ... }:
    let
      # =======================
      # Transpire Configuration
      # =======================

      fs = nixpkgs.lib.fileset;
      allNixFiles = fs.fileFilter (file: file.hasExt "nix") ./.;

      kubernetesExtraModules = fs.toList
        (fs.intersection allNixFiles ./kubernetes/+extras);

      kubernetesModules = fs.toList
        (fs.intersection
          (fs.fileFilter (file: file.hasExt "nix") ./.)
          (fs.difference ./kubernetes ./kubernetes/+extras));

      openApiSpec = ./kube-openapi.json;

      # =====================
      # nixpkgs Configuration
      # =====================

      pkgsFor = system: import nixpkgs {
        inherit system;
        config = { allowUnfree = true; };
      };

      forAllSystems = fn: nixpkgs.lib.genAttrs
        (import systems)
        (system: fn system (pkgsFor system));
    in
    {
      packages = forAllSystems (system: pkgs: {
        kubernetes = transpire.lib.${system}.build.cluster {
          inherit openApiSpec;
          modules = kubernetesModules ++ kubernetesExtraModules;
        };

        # This is used for the `push-vault-secrets` app
        # It's a bit of a hack, but it works for now :)
        __raw-secrets-to-push = builtins.groupBy
          (obj: obj.metadata.namespace)
          (builtins.filter
            (obj: obj.apiVersion == "v1" && obj.kind == "Secret")
            (transpire.lib.${system}.evalModules {
              inherit openApiSpec;
              modules = kubernetesModules;
            }).config.build.objects);
      });

      apps = forAllSystems (system: pkgs: {
        update-kube-openapi = {
          type = "app";
          program = toString (pkgs.writers.writeBash "update-kube-openapi" ''
            ${pkgs.kubectl}/bin/kubectl get --raw /openapi/v2 > kube-openapi.json
          '');
        };

        push-vault-secrets = {
          type = "app";
          program = toString (pkgs.writers.writeBash "push-vault-secrets" ''
            set -e
            if [[ $# -eq 0 ]] ; then
              echo 'Usage: push-vault-secrets <namespace>'
              exit 1
            fi
            nix eval --json --impure ".#__raw-secrets-to-push.$1" \
            | ${pkgs.jq}/bin/jq -r -c '.[] |
                .metadata.namespace + "/" + .metadata.name,
                (.data // {} | .[] |= @base64d) + (.stringData // {})
              ' \
            | while read -r path; read -r data; do
              read -r -p "Push $path? [y/N] " choice <&2
              if [[ $choice =~ ^[Yy] ]] ; then
                ${pkgs.vault-bin}/bin/vault kv put -mount=hfym-ds "$path" - <<< "$data" > /dev/null
              fi
            done
          '');
        };
      });
    };
}
