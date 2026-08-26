{ ... }:

{
  namespaces.bmt-webview.resources = {
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
          };
          # The entrypoint re-clones GIT_REPO_URL on every fresh pod, so the
          # checkout (and the PDFs `make` builds into it) doesn't need to
          # survive restarts.
          volumes.contest-repo.emptyDir = { };
          # The image runs as uid/gid 1000; make the volume writable so the
          # entrypoint can clone into it.
          securityContext.fsGroup = 1000;
          imagePullSecrets = [{ name = "ghcr-auth"; }];
        };
      };
    };

    v1.ConfigMap.webview.data = {
      GIT_REPO_URL = "https://github.com/berkeleymt/bmt-2026.git";
      GIT_PUSH = "1";
      DISCORD_CLIENT_ID = "1108551511233011764";
      DISCORD_GUILD_ID = "786701065856221205";
      DISCORD_REQUIRED_ROLE_IDS = "1532248559892566016";
      DISCORD_REDIRECT_URI = "https://pw.berkeley.mt/api/auth/discord/callback";
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
          host = "pw.berkeley.mt";
          http.paths = [{
            path = "/";
            pathType = "Prefix";
            backend.service = { name = "webview"; port.number = 80; };
          }];
        }];
        tls = [{
          hosts = [ "pw.berkeley.mt" ];
          secretName = "webview-ingress-tls";
        }];
      };
    };
  };
}
