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
      });
    };
}
