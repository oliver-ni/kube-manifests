{ ... }:

{
  namespaces.bmt-ops-dashboard.resources = {
    "postgresql.cnpg.io/v1".Cluster.ops-dashboard-postgres.spec = {
      instances = 1;
      bootstrap.initdb.database = "operations_dashboard";
      storage.size = "2Gi";
    };

    "apps/v1".Deployment.ops-dashboard.spec = {
      replicas = 1;
      selector.matchLabels.app = "ops-dashboard";
      template = {
        metadata.labels.app = "ops-dashboard";
        spec = {
          containers.ops-dashboard = {
            image = "ghcr.io/tri2k/operations-dashboard:latest";
            ports = [{ containerPort = 8001; }];
            env = {
              DB_USER.valueFrom.secretKeyRef = { name = "ops-dashboard-postgres-app"; key = "username"; };
              DB_PASS.valueFrom.secretKeyRef = { name = "ops-dashboard-postgres-app"; key = "password"; };
              DATABASE_URL.value = "postgresql+asyncpg://$(DB_USER):$(DB_PASS)@ops-dashboard-postgres-rw:5432/operations_dashboard";
              CORS_ORIGINS.value = "https://ops.berkeley.mt";
            };
            envFrom = [{ secretRef.name = "ops-dashboard"; }];
            resources = {
              limits = { memory = "512Mi"; };
              requests = { cpu = "50m"; memory = "64Mi"; };
            };
          };
          imagePullSecrets = [{ name = "ghcr-auth"; }];
        };
      };
    };

    v1.Service.ops-dashboard.spec = {
      selector.app = "ops-dashboard";
      ports = [{
        port = 80;
        targetPort = 8001;
      }];
    };

    v1.Secret.ghcr-auth = {
      type = "kubernetes.io/dockerconfigjson";
      stringData.".dockerconfigjson" = "";
    };

    v1.Secret.ops-dashboard.stringData = {
      ADMIN_PASSWORD = "";
      ORGANIZER_PASSWORD = "";
      AUTH_SECRET = "";
    };

    "networking.k8s.io/v1".Ingress.ops-dashboard-ingress = {
      metadata.annotations."cert-manager.io/cluster-issuer" = "letsencrypt";
      spec = {
        ingressClassName = "nginx";
        rules = [{
          host = "ops.berkeley.mt";
          http.paths = [{
            path = "/";
            pathType = "Prefix";
            backend.service = {
              name = "ops-dashboard";
              port.number = 80;
            };
          }];
        }];
        tls = [{
          hosts = [ "ops.berkeley.mt" ];
          secretName = "ops-dashboard-ingress-tls";
        }];
      };
    };
  };
}
