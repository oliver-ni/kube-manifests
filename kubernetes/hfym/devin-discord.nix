{ ... }:

{
  namespaces.devin-discord.resources = {
    "postgresql.cnpg.io/v1".Cluster.devin-discord-postgres.spec = {
      instances = 3;
      bootstrap.initdb.database = "devin_discord";
      storage.size = "8Gi";
    };

    "apps/v1".Deployment.devin-discord.spec = {
      # One gateway connection per bot token; a second replica would answer every message twice.
      replicas = 1;
      strategy.type = "Recreate";
      selector.matchLabels.app = "devin-discord";
      template = {
        metadata.labels.app = "devin-discord";
        spec = {
          containers.devin-discord = {
            image = "ghcr.io/oliver-ni/devin-discord-integration:main";
            # `:main` is a moving tag; without this a restart reuses the node's cached image.
            imagePullPolicy = "Always";
            ports = [{ containerPort = 8080; }];
            env.DATABASE_URL.valueFrom.secretKeyRef = { name = "devin-discord-postgres-app"; key = "uri"; };
            envFrom = [
              { secretRef.name = "devin-discord"; }
              { configMapRef.name = "devin-discord"; }
            ];
            readinessProbe.httpGet = { path = "/readyz"; port = 8080; };
            livenessProbe.httpGet = { path = "/livez"; port = 8080; };
          };
          imagePullSecrets = [{ name = "ghcr-auth"; }];
        };
      };
    };

    v1.ConfigMap.devin-discord.data = {
      PUBLIC_URL = "https://devin-discord.poketwo.io";
      DISCORD_APPLICATION_ID = "1487495269959471196";
      RUST_LOG = "info";
    };

    v1.Secret.devin-discord.stringData = {
      DISCORD_TOKEN = "";
      DISCORD_CLIENT_SECRET = "";
      ENCRYPTION_KEY = "";
    };

    v1.Secret.ghcr-auth = {
      type = "kubernetes.io/dockerconfigjson";
      stringData.".dockerconfigjson" = "";
    };

    v1.Service.devin-discord.spec = {
      selector.app = "devin-discord";
      ports = [{ port = 80; targetPort = 8080; }];
    };

    "networking.k8s.io/v1".Ingress.devin-discord-ingress = {
      metadata.annotations."cert-manager.io/cluster-issuer" = "letsencrypt";
      spec = {
        rules = [{
          host = "devin-discord.poketwo.io";
          http.paths = [{
            path = "/";
            pathType = "Prefix";
            backend.service = { name = "devin-discord"; port.number = 80; };
          }];
        }];
        tls = [{
          hosts = [ "devin-discord.poketwo.io" ];
          secretName = "devin-discord-ingress-tls";
        }];
      };
    };
  };
}
