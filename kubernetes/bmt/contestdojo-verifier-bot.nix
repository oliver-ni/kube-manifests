{ ... }:

{
  namespaces.bmt-contestdojo-verifier-bot.resources = {
    "apps/v1".Deployment.contestdojo-verifier-bot.spec = {
      replicas = 1;
      selector.matchLabels.app = "contestdojo-verifier-bot";
      template = {
        metadata.labels.app = "contestdojo-verifier-bot";
        spec = {
          containers = [{
            name = "contestdojo-verifier-bot";
            image = "ghcr.io/berkeleymt/contestdojo-verifier-bot:latest";
            ports = [{ containerPort = 4887; }];
            envFrom = [{ secretRef.name = "contestdojo-verifier-bot"; }];
            resources = {
              limits = { memory = "4Gi"; };
              requests = { cpu = "200m"; memory = "64Mi"; };
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

    v1.Secret.contestdojo-verifier-bot.stringData = {
      CONTESTDOJO_API_KEY = "";
      BOT_TOKEN = "";
    };
  };
}
