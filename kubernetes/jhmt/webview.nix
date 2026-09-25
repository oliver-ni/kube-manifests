{ ... }:

let
  host = "pw.jhmt.org";
in
{
  namespaces.jhmt-webview.resources = {
    "apps/v1".Deployment.webview.spec = {
      replicas = 1;
      selector.matchLabels.app = "webview";
      template = {
        metadata.labels.app = "webview";
        spec = {
          containers.webview = {
            image = "ghcr.io/atomicgrader/webview:latest";
            ports = [{ containerPort = 3100; }];
            volumeMounts = [{
              name = "contest-repo";
              mountPath = "/app/repo";
            }];
            envFrom = [
              { secretRef.name = "webview"; }
              { configMapRef.name = "webview"; }
            ];
            resources = {
              limits = { memory = "4Gi"; };
              requests = { cpu = "200m"; memory = "256Mi"; };
            };
            readinessProbe = {
              httpGet = { path = "/api/health"; port = 3100; };
              periodSeconds = 10;
            };
          };
          volumes.contest-repo.emptyDir = { };
          securityContext.fsGroup = 1000;
          imagePullSecrets = [{ name = "ghcr-auth"; }];
        };
      };
    };

    v1.ConfigMap.webview.data = {
      GIT_REPO_URL = "https://github.com/jhmt-pw/jhmt-2027.git";
      GIT_PUSH = "1";
      DISCORD_CLIENT_ID = "";
      DISCORD_GUILD_ID = "";
      DISCORD_REQUIRED_ROLE_IDS = "";
      DISCORD_REDIRECT_URI = "https://${host}/api/auth/discord/callback";
    };

    v1.Secret.webview.stringData = {
      WEBVIEW_PASSWORD = "";
      SECRET_KEY = "";
      GITHUB_APP_ID = "";
      GITHUB_APP_PRIVATE_KEY = "";
      GITHUB_APP_INSTALLATION_ID = "";
      DISCORD_CLIENT_SECRET = "";
      DISCORD_BOT_TOKEN = "";
    };

    v1.Secret.ghcr-auth = {
      type = "kubernetes.io/dockerconfigjson";
      stringData.".dockerconfigjson" = "";
    };

    v1.Service.webview.spec = {
      selector.app = "webview";
      ports = [{
        port = 80;
        targetPort = 3100;
      }];
    };

    "networking.k8s.io/v1".Ingress.webview-ingress = {
      metadata.annotations."cert-manager.io/cluster-issuer" = "letsencrypt";
      spec = {
        rules = [{
          inherit host;
          http.paths = [{
            path = "/";
            pathType = "Prefix";
            backend.service = { name = "webview"; port.number = 80; };
          }];
        }];
        tls = [{
          hosts = [ host ];
          secretName = "webview-ingress-tls";
        }];
      };
    };
  };
}
