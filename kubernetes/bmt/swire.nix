{ ... }:

{
  namespaces.bmt.resources = {
    "apps/v1".Deployment.swire-client.spec = {
      replicas = 1;
      selector.matchLabels.app = "swire-client";
      template = {
        metadata.labels.app = "swire-client";
        spec = {
          containers = [{
            name = "swire-client";
            image = "ghcr.io/berkeleymt/swire-client:latest";
            ports = [{ containerPort = 80; }];
            resources = {
              limits = { memory = "128Mi"; };
              requests = { cpu = "100m"; memory = "16Mi"; };
            };
          }];
          imagePullSecrets = [{ name = "ghcr-auth"; }];
        };
      };
    };

    v1.Service.swire-client.spec = {
      selector.app = "swire-client";
      ports = [{ port = 80; }];
    };

    "apps/v1".Deployment.swire-server.spec = {
      replicas = 1;
      selector.matchLabels.app = "swire-server";
      template = {
        metadata.labels.app = "swire-server";
        spec = {
          containers = [{
            name = "swire-server";
            image = "ghcr.io/berkeleymt/swire-server:latest";
            ports = [{ containerPort = 3001; }];
            envFrom = [{ secretRef.name = "swire"; }];
            resources = {
              limits = { memory = "1Gi"; };
              requests = { cpu = "200m"; memory = "64Mi"; };
            };
            volumeMounts = [{
              mountPath = "/app/server/data";
              name = "swire-data";
            }];
          }];
          volumes = [{
            name = "swire-data";
            persistentVolumeClaim.claimName = "swire-data";
          }];
          imagePullSecrets = [{ name = "ghcr-auth"; }];
        };
      };
    };

    v1.Service.swire-server.spec = {
      selector.app = "swire-server";
      ports = [{
        port = 80;
        targetPort = 3001;
      }];
    };

    v1.Secret.swire.stringData = {
      PROCTOR_PASSWORD = "";
      USER_PASSWORD = "";
      SESSION_SECRET = "";
    };

    v1.PersistentVolumeClaim.swire-data.spec = {
      accessModes = [ "ReadWriteOnce" ];
      resources.requests.storage = "16Gi";
    };

    "networking.k8s.io/v1".Ingress.swire-ingress = {
      metadata.annotations."cert-manager.io/cluster-issuer" = "letsencrypt";
      spec = {
        rules = [{
          host = "swire.berkeley.mt";
          http = {
            paths = [
              {
                path = "/api/";
                pathType = "Prefix";
                backend.service = {
                  name = "swire-server";
                  port.number = 80;
                };
              }
              {
                path = "/";
                pathType = "Prefix";
                backend.service = {
                  name = "swire-client";
                  port.number = 80;
                };
              }
            ];
          };
        }];
        tls = [{
          hosts = [ "swire.berkeley.mt" ];
          secretName = "swire-ingress-tls";
        }];
      };
    };
  };
}
