{ ... }:

{
  namespaces.bmt-guts-scoreboard.resources = {
    "apps/v1".Deployment.guts-scoreboard.spec = {
      replicas = 1;
      selector.matchLabels.app = "guts-scoreboard";
      template = {
        metadata.labels.app = "guts-scoreboard";
        spec = {
          containers = [{
            name = "guts-scoreboard";
            image = "ghcr.io/berkeleymt/guts-scoreboard:latest";
            ports = [{ containerPort = 4887; }];
            envFrom = [{ secretRef.name = "guts-scoreboard"; }];
            resources = {
              limits = { memory = "4Gi"; };
              requests = { cpu = "200m"; memory = "64Mi"; };
            };
            volumeMounts = [{
              mountPath = "/data";
              name = "guts-scoreboard-data";
            }];
          }];
          volumes = [{
            name = "guts-scoreboard-data";
            persistentVolumeClaim.claimName = "guts-scoreboard-data";
          }];
          imagePullSecrets = [{ name = "ghcr-auth"; }];
        };
      };
    };

    v1.Secret.ghcr-auth = {
      type = "kubernetes.io/dockerconfigjson";
      stringData.".dockerconfigjson" = "";
    };

    v1.Service.guts-scoreboard.spec = {
      selector.app = "guts-scoreboard";
      ports = [{
        port = 80;
        targetPort = 4887;
      }];
    };

    v1.Secret.guts-scoreboard.stringData = {
      SU_USER = "";
      SU_PASS = "";
    };

    v1.PersistentVolumeClaim.guts-scoreboard-data.spec = {
      accessModes = [ "ReadWriteOnce" ];
      resources.requests.storage = "16Gi";
    };

    "networking.k8s.io/v1".Ingress.guts-scoreboard-ingress = {
      metadata.annotations."cert-manager.io/cluster-issuer" = "letsencrypt";
      spec = {
        rules = [{
          host = "guts.berkeley.mt";
          http.paths = [{
            path = "/";
            pathType = "Prefix";
            backend.service = { name = "guts-scoreboard"; port.number = 80; };
          }];
        }];
        tls = [{
          hosts = [ "guts.berkeley.mt" ];
          secretName = "guts-scoreboard-ingress-tls";
        }];
      };
    };
  };
}
