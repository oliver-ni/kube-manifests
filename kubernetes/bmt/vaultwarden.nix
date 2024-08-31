{ ... }:

{
  namespaces.bmt-vaultwarden.resources = {
    "apps/v1".Deployment.vaultwarden.spec = {
      replicas = 1;
      selector.matchLabels.app = "vaultwarden";
      template = {
        metadata.labels.app = "vaultwarden";
        spec = {
          containers = [{
            name = "vaultwarden";
            image = "vaultwarden/server:1.32.0-alpine";
            ports = [{ containerPort = 80; }];
            volumeMounts = [{
              name = "vaultwarden-data";
              mountPath = "/data";
            }];
            env = [
              { name = "DB_USER"; valueFrom.secretKeyRef = { name = "postgres-app"; key = "username"; }; }
              { name = "DB_PASS"; valueFrom.secretKeyRef = { name = "postgres-app"; key = "password"; }; }
              { name = "DATABASE_URL"; value = "postgres://$(DB_USER):$(DB_PASS)@postgres-rw:5432/vaultwarden"; }
            ];
            envFrom = [
              { secretRef.name = "vaultwarden"; }
              { configMapRef.name = "vaultwarden"; }
            ];
          }];
          volumes = [{
            name = "vaultwarden-data";
            persistentVolumeClaim.claimName = "vaultwarden-data";
          }];
        };
      };
    };

    "postgresql.cnpg.io/v1".Cluster.postgres.spec = {
      instances = 3;
      bootstrap.initdb.database = "vaultwarden";
      storage.size = "1Gi";
    };

    v1.PersistentVolumeClaim.vaultwarden-data.spec = {
      accessModes = [ "ReadWriteOnce" ];
      resources.requests.storage = "1Gi";
    };

    v1.ConfigMap.vaultwarden.data = {
      ROCKET_ADDRESS = "::";
      DOMAIN = "https://bitwarden.berkeley.mt";
      SMTP_HOST = "smtp.resend.com";
      SMTP_PORT = "587";
      SMTP_FROM = "noreply@berkeley.mt";
      SMTP_USERNAME = "resend";
    };

    v1.Secret.vaultwarden.stringData = {
      SMTP_PASSWORD = "insert resend API key";
      ADMIN_TOKEN = "";
    };

    v1.Service.vaultwarden.spec = {
      selector.app = "vaultwarden";
      ports = [{ port = 80; }];
    };

    "networking.k8s.io/v1".Ingress.vaultwarden-ingress = {
      metadata.annotations."cert-manager.io/cluster-issuer" = "letsencrypt";
      spec = {
        rules = [{
          host = "bitwarden.berkeley.mt";
          http.paths = [{
            path = "/";
            pathType = "Prefix";
            backend.service = { name = "vaultwarden"; port.number = 80; };
          }];
        }];
        tls = [{
          hosts = [ "bitwarden.berkeley.mt" ];
          secretName = "vaultwarden-ingress-tls";
        }];
      };
    };
  };
}
