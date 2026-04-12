{ ... }:

{
  namespaces.bmt.resources = {
    v1.PersistentVolumeClaim.live-data.spec = {
      accessModes = [ "ReadWriteOnce" ];
      resources.requests.storage = "1Gi";
    };

    "apps/v1".Deployment.live.spec = {
      replicas = 1;
      selector.matchLabels.app = "live";
      template = {
        metadata.labels.app = "live";
        spec = {
          containers.live = {
            image = "ghcr.io/berkeleymt/live.berkeley.mt:latest";
            ports = [{ containerPort = 3001; }];
            envFrom = [{ secretRef.name = "live"; }];
            env = {
              STATIC_DIR.value = "/app/dist";
              SITE_BASE_URL.value = "https://live.berkeley.mt";
              POSTMARK_FROM_ADDRESS.value = "noreply@berkeley.mt";
            };
            volumeMounts = [{
              name = "data";
              mountPath = "/app/data";
            }];
            command = [ "/app/server" ];
            workingDir = "/app/data";
            resources = {
              limits = { memory = "512Mi"; };
              requests = { cpu = "50m"; memory = "32Mi"; };
            };
          };
          volumes = [{
            name = "data";
            persistentVolumeClaim.claimName = "live-data";
          }];
          imagePullSecrets = [{ name = "ghcr-auth"; }];
        };
      };
    };

    v1.Service.live.spec = {
      selector.app = "live";
      ports = [{
        port = 80;
        targetPort = 3001;
      }];
    };

    v1.Secret.live.stringData = {
      POSTMARK_SERVER_TOKEN = "";
    };

    "networking.k8s.io/v1".Ingress.live-ingress = {
      metadata.annotations."cert-manager.io/cluster-issuer" = "letsencrypt";
      spec = {
        rules = [{
          host = "live.berkeley.mt";
          http.paths = [{
            path = "/";
            pathType = "Prefix";
            backend.service = {
              name = "live";
              port.number = 80;
            };
          }];
        }];
        tls = [{
          hosts = [ "live.berkeley.mt" ];
          secretName = "live-ingress-tls";
        }];
      };
    };
  };
}
