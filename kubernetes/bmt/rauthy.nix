{ ... }:

let
  host = "id.berkeley.mt";
in
{
  namespaces.bmt-auth.resources = {
    "apps/v1".Deployment.rauthy.spec = {
      replicas = 1;
      strategy.type = "Recreate";
      selector.matchLabels.app = "rauthy";
      template = {
        metadata.labels.app = "rauthy";
        spec = {
          containers.rauthy = {
            image = "ghcr.io/sebadob/rauthy:0.36.2";
            ports = [{ containerPort = 8080; }];
            volumeMounts = [
              {
                name = "rauthy-data";
                mountPath = "/app/data";
              }
              {
                name = "rauthy-config";
                mountPath = "/app/config.toml";
                subPath = "config.toml";
                readOnly = true;
              }
            ];
            envFrom = [{ secretRef.name = "rauthy"; }];
            readinessProbe = {
              httpGet = { path = "/ready"; port = 8200; };
              initialDelaySeconds = 5;
              periodSeconds = 3;
              failureThreshold = 2;
            };
            livenessProbe = {
              httpGet = { path = "/auth/v1/health"; port = 8080; };
              initialDelaySeconds = 60;
              periodSeconds = 30;
              failureThreshold = 2;
            };
            resources = {
              limits = { memory = "256Mi"; };
              requests = { cpu = "50m"; memory = "64Mi"; };
            };
            securityContext = {
              allowPrivilegeEscalation = false;
              capabilities.drop = [ "ALL" ];
            };
          };
          volumes = {
            rauthy-data.persistentVolumeClaim.claimName = "rauthy-data";
            rauthy-config.configMap.name = "rauthy";
          };
          securityContext = {
            runAsUser = 10001;
            runAsGroup = 10001;
            runAsNonRoot = true;
            fsGroup = 10001;
          };
        };
      };
    };

    v1.PersistentVolumeClaim.rauthy-data.spec = {
      accessModes = [ "ReadWriteOnce" ];
      resources.requests.storage = "1Gi";
    };

    v1.Service.rauthy.spec = {
      selector.app = "rauthy";
      ports = [{
        port = 80;
        targetPort = 8080;
      }];
    };

    # Non-sensitive config; secrets come from the `rauthy` Secret as env
    # vars, which override the matching config.toml keys.
    v1.ConfigMap.rauthy.data."config.toml" = ''
      [cluster]
      node_id = 1
      nodes = ["1 localhost:8100 localhost:8200"]

      [email]
      smtp_url = "smtp.resend.com"
      smtp_username = "resend"
      smtp_from = "BMT Auth <noreply@berkeley.mt>"

      [server]
      scheme = "http"
      pub_url = "${host}"
      proxy_mode = true
      trusted_proxies = ["2606:c2c0:5:1::/64"]
      http_workers = 2

      [webauthn]
      rp_id = "${host}"
      rp_origin = "https://${host}:443"
    '';

    v1.Secret.rauthy.stringData = {
      # Hiqlite (single node, but still required)
      HQL_SECRET_RAFT = "";
      HQL_SECRET_API = "";
      # `openssl rand -hex 4`  ->  key id
      # `openssl rand -base64 32`  ->  key
      # ENC_KEYS = "<id>/<key>", ENC_KEY_ACTIVE = "<id>"
      ENC_KEYS = "";
      ENC_KEY_ACTIVE = "";
      # Resend API key
      SMTP_PASSWORD = "";
    };

    "networking.k8s.io/v1".Ingress.rauthy-ingress = {
      metadata.annotations."cert-manager.io/cluster-issuer" = "letsencrypt";
      spec = {
        rules = [{
          inherit host;
          http.paths = [{
            path = "/";
            pathType = "Prefix";
            backend.service = { name = "rauthy"; port.number = 80; };
          }];
        }];
        tls = [{
          hosts = [ host ];
          secretName = "rauthy-ingress-tls";
        }];
      };
    };
  };
}
