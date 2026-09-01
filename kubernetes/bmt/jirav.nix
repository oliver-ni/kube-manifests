{ ... }:

{
  namespaces.bmt-jirav.resources = {
    "apps/v1".Deployment.jirav.spec = {
      replicas = 1;
      strategy.type = "Recreate";
      selector.matchLabels.app = "jirav";
      template = {
        metadata.labels.app = "jirav";
        spec = {
          containers.jirav = {
            image = "ghcr.io/berkeleymt/jirav:latest";
            ports = [{ containerPort = 3001; }];
            volumeMounts = [{
              name = "jirav-data";
              mountPath = "/data";
            }];
            env = {
              DATA_DIR.value = "/data";
              HOST.value = "::";
            };
            envFrom = [{ secretRef.name = "jirav"; }];
            resources = {
              limits = { memory = "512Mi"; };
              requests = { cpu = "100m"; memory = "128Mi"; };
            };
          };
          volumes.jirav-data = {
            persistentVolumeClaim.claimName = "jirav-data";
          };
          imagePullSecrets = [{ name = "ghcr-auth"; }];
        };
      };
    };

    v1.PersistentVolumeClaim.jirav-data.spec = {
      accessModes = [ "ReadWriteOnce" ];
      resources.requests.storage = "1Gi";
    };

    v1.Service.jirav.spec = {
      selector.app = "jirav";
      ports = [{
        port = 80;
        targetPort = 3001;
      }];
    };

    v1.Secret.jirav.stringData = {
      GOOGLE_CLIENT_ID = "";
      SESSION_SECRET = "";
      GOOGLE_SERVICE_ACCOUNT_JSON = "";
    };

    v1.Secret.ghcr-auth = {
      type = "kubernetes.io/dockerconfigjson";
      stringData.".dockerconfigjson" = "";
    };

    "networking.k8s.io/v1".Ingress.jirav-ingress = {
      metadata.annotations."cert-manager.io/cluster-issuer" = "letsencrypt";
      spec = {
        rules = [{
          host = "jirav.berkeley.mt";
          http.paths = [{
            path = "/";
            pathType = "Prefix";
            backend.service = { name = "jirav"; port.number = 80; };
          }];
        }];
        tls = [{
          hosts = [ "jirav.berkeley.mt" ];
          secretName = "jirav-ingress-tls";
        }];
      };
    };
  };
}
