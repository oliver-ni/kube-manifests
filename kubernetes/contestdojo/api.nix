{
  namespaces.contestdojo-api.resources = {
    "apps/v1".Deployment.contestdojo-api.spec = {
      replicas = 1;
      selector.matchLabels.app = "contestdojo-api";
      template = {
        metadata.labels.app = "contestdojo-api";
        spec.containers = [{
          name = "contestdojo-api";
          image = "ghcr.io/contestdojo/api:main";
          imagePullPolicy = "Always";
          ports = [{ containerPort = 8000; }];
          resources = {
            limits = { memory = "500Mi"; };
            requests = { memory = "50Mi"; cpu = "50m"; };
          };
          envFrom = [{ secretRef = { name = "contestdojo-api"; }; }];
        }];
      };
    };

    v1.Service.contestdojo-api.spec = {
      selector.app = "contestdojo-api";
      ports = [{ port = 8000; }];
    };

    "networking.k8s.io/v1".Ingress.contestdojo-api-ingress = {
      metadata.annotations."cert-manager.io/cluster-issuer" = "letsencrypt";
      spec = {
        ingressClassName = "nginx";
        rules = [{
          host = "api.contestdojo.com";
          http.paths = [{
            path = "/";
            pathType = "Prefix";
            backend.service = { name = "contestdojo-api"; port.number = 8000; };
          }];
        }];
        tls = [{
          hosts = [ "api.contestdojo.com" ];
          secretName = "contestdojo-api-ingress-tls";
        }];
      };
    };

    v1.Secret.contestdojo-api.stringData = {
      FIREBASE_CERTIFICATE = "";
    };
  };
}
