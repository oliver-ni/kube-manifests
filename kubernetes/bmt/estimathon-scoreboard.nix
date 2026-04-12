{ ... }:

{
  namespaces.bmt.resources = {
    "postgresql.cnpg.io/v1".Cluster.estimathon-scoreboard-postgres.spec = {
      instances = 3;
      bootstrap.initdb.database = "estimathon";
      storage.size = "8Gi";
    };

    "apps/v1".Deployment.estimathon-scoreboard.spec = {
      replicas = 1;
      selector.matchLabels.app = "estimathon-scoreboard";
      template = {
        metadata.labels.app = "estimathon-scoreboard";
        spec = {
          containers.estimathon-scoreboard = {
            image = "ghcr.io/berkeleymt/estimathon-scoreboard:latest";
            ports = [{ containerPort = 8080; }];
            env = {
              DATABASE_URL.valueFrom.secretKeyRef = { name = "estimathon-scoreboard-postgres-app"; key = "uri"; };
            };
            envFrom = [{ secretRef.name = "estimathon-scoreboard"; }];
            resources = {
              limits = { memory = "512Mi"; };
              requests = { cpu = "100m"; memory = "64Mi"; };
            };
          };
          imagePullSecrets = [{ name = "ghcr-auth"; }];
        };
      };
    };

    v1.Service.estimathon-scoreboard.spec = {
      selector.app = "estimathon-scoreboard";
      ports = [{
        port = 80;
        targetPort = 8080;
      }];
    };

    v1.Service.estimathon-scoreboard-postgres-lb.spec = {
      type = "LoadBalancer";
      selector = {
        "cnpg.io/cluster" = "estimathon-scoreboard-postgres";
        role = "primary";
      };
      ports = [{
        port = 5432;
        targetPort = 5432;
      }];
    };

    v1.Secret.estimathon-scoreboard.stringData = {
      JWT_SECRET = "";
    };

    "networking.k8s.io/v1".Ingress.estimathon-scoreboard-ingress = {
      metadata.annotations."cert-manager.io/cluster-issuer" = "letsencrypt";
      spec = {
        rules = [{
          host = "estimathon.berkeley.mt";
          http.paths = [{
            path = "/";
            pathType = "Prefix";
            backend.service = { name = "estimathon-scoreboard"; port.number = 80; };
          }];
        }];
        tls = [{
          hosts = [ "estimathon.berkeley.mt" ];
          secretName = "estimathon-scoreboard-ingress-tls";
        }];
      };
    };
  };
}
