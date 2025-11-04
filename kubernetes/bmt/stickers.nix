{ ... }:

{
  namespaces.bmt-stickers.resources = {
    "apps/v1".Deployment.stickers.spec = {
      replicas = 1;
      selector.matchLabels.app = "stickers";
      template = {
        metadata.labels.app = "stickers";
        spec = {
          containers = [{
            name = "stickers";
            image = "ghcr.io/berkeleymt/stickers:latest";
            envFrom = [{ secretRef.name = "stickers"; }];
            resources = {
              limits = { memory = "512Mi"; };
              requests = { cpu = "20m"; memory = "64Mi"; };
            };
          }];
          imagePullSecrets = [{ name = "ghcr-auth"; }];
        };
      };
    };

    v1.Secret.ghcr-auth = {
      type = "kubernetes.io/dockerconfigjson";
      stringData.".dockerconfigjson" = "";
    };

    v1.Secret.stickers.stringData = {
      CONTESTDOJO_API_KEY = "";
      AUTH_USERNAME = "";
      AUTH_PASSWORD = "";
    };
  };
}
