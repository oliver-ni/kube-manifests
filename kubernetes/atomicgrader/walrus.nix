{ ... }:

{
  namespaces.atomicgrader.resources = {
    "apps/v1".Deployment.ag-walrus.spec = {
      replicas = 1;
      selector.matchLabels.app = "ag-walrus";
      template = {
        metadata.labels.app = "ag-walrus";
        spec = {
          containers = [{
            name = "walrus";
            image = "ghcr.io/atomicgrader/walrus:latest";
            ports = [{ containerPort = 3000; }];
            resources = {
              limits = { memory = "4Gi"; cpu = "500m"; };
              requests = { memory = "1Gi"; cpu = "50m"; };
            };
            env = [{
              name = "GRAPHQL_URL";
              value = "https://ag.poketwo.io/graphql";
            }];
          }];
          imagePullSecrets = [{ name = "ghcr-auth"; }];
        };
      };
    };

    v1.Service.ag-walrus.spec = {
      selector.app = "ag-walrus";
      ports = [{ port = 80; targetPort = 3000; }];
    };
  };
}
