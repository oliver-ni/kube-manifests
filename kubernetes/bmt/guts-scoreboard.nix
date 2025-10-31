{ ... }:

{
  namespaces.bmt-guts-scoreboard.resources = {
    "postgresql.cnpg.io/v1".Cluster.guts-scoreboard-postgres.spec = {
      instances = 3;
      bootstrap.initdb.database = "guts_scoreboard";
      storage.size = "8Gi";
    };

    "apps/v1".Deployment.guts-scoreboard.spec = {
      replicas = 1;
      selector.matchLabels.app = "guts-scoreboard";
      template = {
        metadata.labels.app = "guts-scoreboard";
        spec = {
          containers = [{
            name = "guts-scoreboard";
            image = "ghcr.io/berkeleymt/guts-scoreboard:latest";
            ports = [{ containerPort = 4887; }];
            env = [
              { name = "DB_USER"; valueFrom.secretKeyRef = { name = "guts-scoreboard-postgres-app"; key = "username"; }; }
              { name = "DB_PASS"; valueFrom.secretKeyRef = { name = "guts-scoreboard-postgres-app"; key = "password"; }; }
              { name = "DATABASE_URL"; value = "postgres://$(DB_USER):$(DB_PASS)@guts-scoreboard-postgres-rw:5432/guts_scoreboard"; }
              { name = "RUST_LOG"; value = "tower_http=trace"; }
            ];
            envFrom = [{ secretRef.name = "guts-scoreboard"; }];
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

    v1.Service.guts-scoreboard.spec = {
      selector.app = "guts-scoreboard";
      ports = [{
        port = 80;
        targetPort = 4887;
      }];
    };

    v1.Secret.guts-scoreboard.stringData = {
      SU_USER = "";
      SU_PASS = "";
    };

    "networking.k8s.io/v1".Ingress.guts-scoreboard-ingress = {
      metadata.annotations."cert-manager.io/cluster-issuer" = "letsencrypt";
      spec = {
        rules = [{
          host = "guts.berkeley.mt";
          http.paths = [{
            path = "/";
            pathType = "Prefix";
            backend.service = { name = "guts-scoreboard"; port.number = 80; };
          }];
        }];
        tls = [{
          hosts = [ "guts.berkeley.mt" ];
          secretName = "guts-scoreboard-ingress-tls";
        }];
      };
    };
  };
}
