{ ... }:

{
  namespaces.bmt-discord-bot.resources = {
    "postgresql.cnpg.io/v1".Cluster.discord-bot-postgres.spec = {
      instances = 3;
      bootstrap.initdb.database = "bmt_discord_bot";
      storage.size = "8Gi";
    };

    "apps/v1".Deployment.discord-bot.spec = {
      replicas = 1;
      selector.matchLabels.app = "discord-bot";
      template = {
        metadata.labels.app = "discord-bot";
        spec = {
          containers = [{
            name = "discord-bot";
            image = "ghcr.io/berkeleymt/discord-bot:latest";
            env = [
              { name = "DB_USER"; valueFrom.secretKeyRef = { name = "discord-bot-postgres-app"; key = "username"; }; }
              { name = "DB_PASS"; valueFrom.secretKeyRef = { name = "discord-bot-postgres-app"; key = "password"; }; }
              { name = "DB_URI"; value = "postgres://$(DB_USER):$(DB_PASS)@discord-bot-postgres-rw:5432/bmt_discord_bot"; }
            ];
            envFrom = [{ secretRef.name = "discord-bot"; }];
            resources = {
              limits = { memory = "4Gi"; };
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

    v1.Secret.discord-bot.stringData = {
      BOT_TOKEN = "";
    };
  };
}
