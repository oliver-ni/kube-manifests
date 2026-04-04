{ ... }:

{
  namespaces.bmt.resources = {
    "postgresql.cnpg.io/v1".Cluster.swire2-postgres.spec = {
      instances = 1;
      bootstrap.initdb.database = "swire2";
      storage.size = "8Gi";
    };

    "apps/v1".Deployment.swire2.spec = {
      replicas = 1;
      selector.matchLabels.app = "swire2";
      template = {
        metadata.labels.app = "swire2";
        spec = {
          containers.swire2 = {
            image = "ghcr.io/berkeleymt/swire2:latest";
            ports = [{ containerPort = 8000; }];
            envFrom = [{ secretRef.name = "swire2"; }];
            env = {
              DATABASE_URL.valueFrom.secretKeyRef = {
                name = "swire2-postgres-app";
                key = "uri";
              };
              APP_ENV.value = "production";
              SERVE_FRONTEND.value = "true";
              RUN_MIGRATIONS.value = "true";
              CORS_ALLOW_ORIGINS.value = "https://swire.berkeley.mt";
              SUPER_ADMIN_EMAIL_OTP_REQUIRED.value = "false";
              PROCTOR_EMAIL_LOGIN_ENABLED.value = "false";
              PORT.value = "8000";
              WEB_CONCURRENCY.value = "2";
              API_BASE_URL.value = "https://swire.berkeley.mt";
            };
            resources = {
              limits = { memory = "1Gi"; };
              requests = { cpu = "200m"; memory = "64Mi"; };
            };
            livenessProbe = {
              httpGet = { path = "/health"; port = 8000; };
              periodSeconds = 10;
            };
            readinessProbe = {
              httpGet = { path = "/health/db"; port = 8000; };
              periodSeconds = 10;
            };
          };
          imagePullSecrets = [{ name = "ghcr-auth"; }];
        };
      };
    };

    v1.Service.swire2.spec = {
      selector.app = "swire2";
      ports = [{
        port = 80;
        targetPort = 8000;
      }];
    };

    v1.Secret.swire2.stringData = {
      JWT_SECRET = "";
      INITIAL_SHARED_ADMIN_PASSWORD = "";
      INITIAL_SHARED_PROCTOR_PASSWORD = "";
    };

    "networking.k8s.io/v1".Ingress.swire2-ingress = {
      metadata.annotations."cert-manager.io/cluster-issuer" = "letsencrypt";
      spec = {
        rules = [{
          host = "swire.berkeley.mt";
          http.paths = [{
            path = "/";
            pathType = "Prefix";
            backend.service = {
              name = "swire2";
              port.number = 80;
            };
          }];
        }];
        tls = [{
          hosts = [ "swire.berkeley.mt" ];
          secretName = "swire2-ingress-tls";
        }];
      };
    };
  };
}
