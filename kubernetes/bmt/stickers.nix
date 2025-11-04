{ ... }:

{
  namespaces.bmt-stickers.resources = {
    "apps/v1".Deployment.stickers.spec = {
      replicas = 1;
      selector.matchLabels.app = "stickers";
      template = {
        metadata.labels.app = "stickers";
        spec = {
          containers = [{
            name = "stickers";
            image = "ghcr.io/berkeleymt/stickers:latest";
            ports = [{ containerPort = 8000; }];
            envFrom = [{ secretRef.name = "stickers"; }];
            resources = {
              limits = { memory = "512Mi"; };
              requests = { cpu = "20m"; memory = "64Mi"; };
            };
          }];
          imagePullSecrets = [{ name = "ghcr-auth"; }];
        };
      };
    };

    v1.Service.stickers.spec = {
      selector.app = "stickers";
      ports = [{
        port = 80;
        targetPort = 8000;
      }];
    };

    v1.Secret.ghcr-auth = {
      type = "kubernetes.io/dockerconfigjson";
      stringData.".dockerconfigjson" = "";
    };

    v1.Secret.stickers.stringData = {
      CONTESTDOJO_API_KEY = "";
      AUTH_USERNAME = "";
      AUTH_PASSWORD = "";
    };

    "networking.k8s.io/v1".Ingress.stickers-ingress = {
      metadata.annotations."cert-manager.io/cluster-issuer" = "letsencrypt";
      spec = {
        rules = [{
          host = "stickers.berkeley.mt";
          http = {
            paths = [{
              path = "/";
              pathType = "Prefix";
              backend.service = {
                name = "stickers";
                port.number = 80;
              };
            }];
          };
        }];
        tls = [{
          hosts = [ "stickers.berkeley.mt" ];
          secretName = "stickers-ingress-tls";
        }];
      };
    };
  };
}
