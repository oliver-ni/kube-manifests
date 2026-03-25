{ ... }:

{
  namespaces.afd-icon.resources = {
    "apps/v1".Deployment.afd-icon.spec = {
      replicas = 4;
      selector.matchLabels.app = "afd-icon";
      template = {
        metadata.labels.app = "afd-icon";
        spec.containers = [{
          name = "afd-icon";
          image = "ghcr.io/oliver-ni/afd-icon:latest";
          ports = [{ containerPort = 8000; }];
          resources = {
            limits = { cpu = "500m"; memory = "4Gi"; };
            requests = { cpu = "500m"; memory = "4Gi"; };
          };
        }];
      };
    };

    v1.Service.afd-icon.spec = {
      selector.app = "afd-icon";
      ports = [{ port = 8000; }];
    };

    "networking.k8s.io/v1".Ingress.afd-icon-ingress.spec = {
      ingressClassName = "nginx";
      rules = [{
        host = "afdicon.poketwo.io";
        http.paths = [{
          path = "/";
          pathType = "Prefix";
          backend.service = {
            name = "afd-icon";
            port.number = 8000;
          };
        }];
      }];
    };
  };
}
