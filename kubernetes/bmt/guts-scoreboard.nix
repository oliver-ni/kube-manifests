{ ... }:

{
  namespaces.guts.resources = {
    "apps/v1".Deployment.guts-scoreboard.spec = {
      replicas = 1;
      selector.matchLabels.app = "guts-scoreboard";
      template = {
        metadata.labels.app = "guts-scoreboard";
        spec = {
          containers = [{
            name = "guts";
            image = "registry.gitlab.com/atomicgrader/guts-scoreboard:latest";
            ports = [{ containerPort = 80; }];
            resources = {
              limits = { memory = "128Mi"; };
              requests = { cpu = "100m"; memory = "16Mi"; };
            };
          }];
          imagePullSecrets = [{ name = "guts-scoreboard-auth"; }];
        };
      };
    };

    v1.Service.guts-scoreboard.spec = {
      selector.app = "guts-scoreboard";
      ports = [{ port = 80; }];
    };

    v1.PersistentVolumeClaim.guts-data.spec = {
      accessModes = [ "ReadWriteOnce" ];
      resources.requests.storage = "16Gi";
    };

    "networking.k8s.io/v1".Ingress.guts-ingress = {
      metadata.annotations."cert-manager.io/cluster-issuer" = "letsencrypt";
      spec = {
        rules = [{
          host = "guts.poketwo.io";
          http = {
            paths = [
              {
                path = "/";
                pathType = "Prefix";
                backend.service = {
                  name = "guts-scoreboard";
                  port.number = 80;
                };
              }
            ];
          };
        }];
        tls = [{
          hosts = [ "guts.poketwo.io" ];
          secretName = "guts-ingress-tls";
        }];
      };
    };
  };
}

