{ ... }:

{
  namespaces.atomicgrader.resources = {
    "networking.k8s.io/v1".Ingress.ag-ingress = {
      metadata.annotations = {
        "nginx.ingress.kubernetes.io/proxy-body-size" = "100M";
        "cert-manager.io/cluster-issuer" = "letsencrypt";
      };
      spec = {
        rules = [{
          host = "ag.poketwo.io";
          http.paths = [
            { path = "/graphql"; pathType = "Prefix"; backend.service = { name = "ag-otter"; port.number = 80; }; }
            { path = "/auth"; pathType = "Prefix"; backend.service = { name = "ag-otter"; port.number = 80; }; }
            { path = "/api/exam"; pathType = "Prefix"; backend.service = { name = "ag-otter"; port.number = 80; }; }
            { path = "/admin"; pathType = "Prefix"; backend.service = { name = "ag-otter"; port.number = 80; }; }
            { path = "/silk"; pathType = "Prefix"; backend.service = { name = "ag-otter"; port.number = 80; }; }
            { path = "/media"; pathType = "Prefix"; backend.service = { name = "ag-assets"; port.number = 80; }; }
            { path = "/static"; pathType = "Prefix"; backend.service = { name = "ag-assets"; port.number = 80; }; }
            { path = "/"; pathType = "Prefix"; backend.service = { name = "ag-walrus"; port.number = 80; }; }
          ];
        }];
        tls = [{
          hosts = [ "ag.poketwo.io" ];
          secretName = "ag-ingress-tls";
        }];
      };
    };
  };
}
