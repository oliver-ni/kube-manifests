{ ... }:

{
  namespaces.bmt-volunteers.resources = {
    "postgresql.cnpg.io/v1".Cluster.volunteers-postgres.spec = {
      instances = 3;
      bootstrap.initdb.database = "volunteers";
      storage.size = "8Gi";
    };

    # One replica: live updates and check-in locking are in-process.
    "apps/v1".Deployment.volunteers.spec = {
      replicas = 1;
      strategy.type = "Recreate";
      selector.matchLabels.app = "volunteers";
      template = {
        metadata.labels.app = "volunteers";
        spec = {
          containers.volunteers = {
            image = "ghcr.io/berkeleymt/volunteer-check-in:latest";
            imagePullPolicy = "Always";
            ports = [{ containerPort = 3000; }];
            env = {
              DB_USER.valueFrom.secretKeyRef = { name = "volunteers-postgres-app"; key = "username"; };
              DB_PASS.valueFrom.secretKeyRef = { name = "volunteers-postgres-app"; key = "password"; };
              DATABASE_URL.value = "postgres://$(DB_USER):$(DB_PASS)@volunteers-postgres-rw:5432/volunteers";
              PUBLIC_URL.value = "https://volunteers.berkeley.mt";
            };
            envFrom = [{ secretRef.name = "volunteers"; }];
            resources = {
              limits = { memory = "512Mi"; };
              requests = { cpu = "100m"; memory = "64Mi"; };
            };
          };
          imagePullSecrets = [{ name = "ghcr-auth"; }];
        };
      };
    };

    v1.Secret.ghcr-auth = {
      type = "kubernetes.io/dockerconfigjson";
      stringData.".dockerconfigjson" = "";
    };

    v1.Secret.volunteers.stringData = {
      ADMIN_PASSWORD = "";
      GOOGLE_CLIENT_ID = "";
      GOOGLE_CLIENT_SECRET = "";
    };

    v1.Service.volunteers.spec = {
      selector.app = "volunteers";
      ports = [{
        port = 80;
        targetPort = 3000;
      }];
    };

    "networking.k8s.io/v1".Ingress.volunteers-ingress = {
      metadata.annotations = {
        "cert-manager.io/cluster-issuer" = "letsencrypt";
        "nginx.ingress.kubernetes.io/proxy-body-size" = "10M";
        # Live updates are a long-lived event stream.
        "nginx.ingress.kubernetes.io/proxy-buffering" = "off";
        "nginx.ingress.kubernetes.io/proxy-read-timeout" = "3600";
      };
      spec = {
        rules = [{
          host = "volunteers.berkeley.mt";
          http.paths = [{
            path = "/";
            pathType = "Prefix";
            backend.service = { name = "volunteers"; port.number = 80; };
          }];
        }];
        tls = [{
          hosts = [ "volunteers.berkeley.mt" ];
          secretName = "volunteers-ingress-tls";
        }];
      };
    };

    "networking.k8s.io/v1".Ingress.volunteers-redirect = {
      metadata.annotations = {
        "cert-manager.io/cluster-issuer" = "letsencrypt";
        "nginx.ingress.kubernetes.io/permanent-redirect" = "https://volunteers.berkeley.mt$request_uri";
      };
      spec = {
        rules = [{
          host = "volunteers-new.berkeley.mt";
          http.paths = [{
            path = "/";
            pathType = "Prefix";
            backend.service = { name = "volunteers"; port.number = 80; };
          }];
        }];
        tls = [{
          hosts = [ "volunteers-new.berkeley.mt" ];
          secretName = "volunteers-redirect-tls";
        }];
      };
    };
  };
}
