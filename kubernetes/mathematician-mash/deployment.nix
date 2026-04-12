{ ... }:

{
  namespaces.mathematician-mash.resources = {
    v1.PersistentVolumeClaim.mathematician-mash-data.spec = {
      accessModes = [ "ReadWriteOnce" ];
      resources.requests.storage = "1Gi";
    };

    "apps/v1".Deployment.mathematician-mash.spec = {
      replicas = 1;
      selector.matchLabels.app = "mathematician-mash";
      template = {
        metadata.labels.app = "mathematician-mash";
        spec = {
          containers.mathematician-mash = {
            image = "ghcr.io/berkeleymt/mathematician-mash:latest";
            ports = [{ containerPort = 8000; }];
            volumeMounts = [{
              name = "data";
              mountPath = "/data";
            }];
            resources = {
              limits = { memory = "4Gi"; };
              requests = { cpu = "20m"; memory = "64Mi"; };
            };
          };
          volumes = [{
            name = "data";
            persistentVolumeClaim.claimName = "mathematician-mash-data";
          }];
          imagePullSecrets = [{ name = "ghcr-auth"; }];
        };
      };
    };

    v1.Service.mathematician-mash.spec = {
      selector.app = "mathematician-mash";
      ports = [{
        port = 80;
        targetPort = 8000;
      }];
    };

    v1.Secret.ghcr-auth = {
      type = "kubernetes.io/dockerconfigjson";
      stringData.".dockerconfigjson" = "";
    };

    "networking.k8s.io/v1".Ingress.mathematician-mash-ingress = {
      metadata.annotations."cert-manager.io/cluster-issuer" = "letsencrypt";
      spec = {
        rules = [{
          host = "m2.berkeley.mt";
          http.paths = [{
            path = "/";
            pathType = "Prefix";
            backend.service = {
              name = "mathematician-mash";
              port.number = 80;
            };
          }];
        }];
        tls = [{
          hosts = [ "m2.berkeley.mt" ];
          secretName = "mathematician-mash-ingress-tls";
        }];
      };
    };
  };
}
