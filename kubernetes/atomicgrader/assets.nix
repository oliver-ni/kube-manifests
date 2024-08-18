{ ... }:

{
  namespaces.atomicgrader.resources = {
    v1.PersistentVolumeClaim.ag-assets.spec = {
      storageClassName = "cephfs-nvme-retain";
      accessModes = [ "ReadWriteMany" ];
      resources.requests.storage = "64Gi";
    };

    "apps/v1".Deployment.ag-assets.spec = {
      selector.matchLabels.app = "ag-assets";
      template = {
        metadata.labels.app = "ag-assets";
        spec = {
          containers = [{
            name = "ag-assets";
            image = "nginx:1.23.4-alpine-slim";
            ports = [{ containerPort = 80; }];
            resources = {
              limits = { memory = "1Gi"; };
              requests = { cpu = "50m"; memory = "50Mi"; };
            };
            volumeMounts = [{
              mountPath = "/usr/share/nginx/html";
              name = "ag-assets";
            }];
          }];
          volumes = [{
            name = "ag-assets";
            persistentVolumeClaim.claimName = "ag-assets";
          }];
        };
      };
    };

    v1.Service.ag-assets.spec = {
      selector.app = "ag-assets";
      ports = [{ port = 80; }];
    };
  };
}
