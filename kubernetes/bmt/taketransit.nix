{ ... }:

{
  namespaces.bmt.resources = {
    "apps/v1".Deployment.taketransit.spec = {
      replicas = 1;
      selector.matchLabels.app = "taketransit";
      template = {
        metadata.labels.app = "taketransit";
        spec = {
          containers.taketransit = {
            image = "ghcr.io/berkeleymt/taketransit:latest";
            ports = [{ containerPort = 8080; }];
            resources = {
              limits = { memory = "128Mi"; };
              requests = { cpu = "10m"; memory = "16Mi"; };
            };
          };
          imagePullSecrets = [{ name = "ghcr-auth"; }];
        };
      };
    };

    v1.Service.taketransit.spec = {
      selector.app = "taketransit";
      ports = [{
        port = 80;
        targetPort = 8080;
      }];
    };

    "networking.k8s.io/v1".Ingress.taketransit-ingress = {
      metadata.annotations."cert-manager.io/cluster-issuer" = "letsencrypt";
      spec = {
        rules = [{
          host = "transit.berkeley.mt";
          http.paths = [{
            path = "/";
            pathType = "Prefix";
            backend.service = {
              name = "taketransit";
              port.number = 80;
            };
          }];
        }];
        tls = [{
          hosts = [ "transit.berkeley.mt" ];
          secretName = "taketransit-ingress-tls";
        }];
      };
    };
  };
}
