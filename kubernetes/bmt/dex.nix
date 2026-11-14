# OIDC provider at id.berkeley.mt.
#
# Dex has no users of its own: Discord is the only login, and the ID token's
# `groups` claim carries the member's role IDs in the BMT server.

{ ... }:

let
  host = "id.berkeley.mt";
  port = 5556;

  config = builtins.toJSON {
    issuer = "https://${host}";

    # The cluster is IPv6-only.
    web.http = "[::]:${toString port}";

    storage = {
      type = "sqlite3";
      config.file = "/var/dex/dex.db";
    };

    oauth2.skipApprovalScreen = true;

    connectors = [{
      type = "oauth";
      id = "discord";
      name = "Discord";

      config = {
        # Same Discord app as webview and guts-scoreboard.
        clientID = "1108551511233011764";
        # Dex fills this in from its environment at startup.
        clientSecret = "$DISCORD_CLIENT_SECRET";
        redirectURI = "https://${host}/callback";
        scopes = [ "identify" "email" "guilds.members.read" ];

        authorizationURL = "https://discord.com/oauth2/authorize";
        tokenURL = "https://discord.com/api/oauth2/token";
        # The discord-userinfo sidecar, which adds the roles Discord's own
        # userinfo call leaves out.
        userInfoURL = "http://[::1]:8081/";
      };
    }];

    # One entry per app, with its secret as a key in the `dex` Secret:
    #   { id = "volunteers"; name = "Volunteers"; secretEnv = "VOLUNTEERS_CLIENT_SECRET";
    #     redirectURIs = [ "https://volunteers.berkeley.mt/auth/callback" ]; }
    staticClients = [ ];
  };

  userinfo = builtins.readFile ./dex-discord-userinfo.py;
in
{
  namespaces.bmt-auth.resources = {
    "apps/v1".Deployment.dex.spec = {
      replicas = 1;
      strategy.type = "Recreate";
      selector.matchLabels.app = "dex";

      template = {
        metadata.labels.app = "dex";
        # Both files are subPath mounts, so the pod only sees changes on restart.
        metadata.annotations."checksum/config" = builtins.hashString "sha256" (config + userinfo);

        spec = {
          containers.dex = {
            image = "ghcr.io/dexidp/dex:v2.46.1";
            command = [ "dex" "serve" "/etc/dex/config.yaml" ];
            ports = [{ containerPort = port; }];
            envFrom = [{ secretRef.name = "dex"; }];

            volumeMounts = [
              {
                name = "dex-data";
                mountPath = "/var/dex";
              }
              {
                name = "dex-config";
                mountPath = "/etc/dex/config.yaml";
                subPath = "config.yaml";
                readOnly = true;
              }
            ];

            readinessProbe.httpGet = { path = "/healthz"; inherit port; };
          };

          containers.discord-userinfo = {
            image = "python:3.13-alpine";
            command = [ "python" "/app/userinfo.py" ];
            # The BMT server, whose role IDs end up in `groups`.
            env.DISCORD_GUILD_ID.value = "786701065856221205";

            volumeMounts = [{
              name = "dex-config";
              mountPath = "/app/userinfo.py";
              subPath = "userinfo.py";
              readOnly = true;
            }];
          };

          volumes = {
            dex-data.persistentVolumeClaim.claimName = "dex-data";
            dex-config.configMap.name = "dex";
          };

          securityContext = {
            runAsUser = 1001;
            runAsGroup = 1001;
            runAsNonRoot = true;
            fsGroup = 1001;
          };
        };
      };
    };

    v1.Service.dex.spec = {
      selector.app = "dex";
      ports = [{
        port = 80;
        targetPort = port;
      }];
    };

    "networking.k8s.io/v1".Ingress.dex-ingress = {
      metadata.annotations."cert-manager.io/cluster-issuer" = "letsencrypt";

      spec = {
        rules = [{
          inherit host;
          http.paths = [{
            path = "/";
            pathType = "Prefix";
            backend.service = { name = "dex"; port.number = 80; };
          }];
        }];

        tls = [{
          hosts = [ host ];
          secretName = "dex-ingress-tls";
        }];
      };
    };

    v1.ConfigMap.dex.data = {
      "config.yaml" = config;
      "userinfo.py" = userinfo;
    };

    # Filled in from Vault.
    v1.Secret.dex.stringData = {
      DISCORD_CLIENT_SECRET = "";
    };

    # Signing keys and refresh tokens.
    v1.PersistentVolumeClaim.dex-data.spec = {
      accessModes = [ "ReadWriteOnce" ];
      resources.requests.storage = "1Gi";
    };
  };
}
