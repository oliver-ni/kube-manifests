{ ... }:

let
  image = "ghcr.io/berkeleymt/bph-site:latest";

  # The server requires all three at runtime (see server/src/lib/env.ts).
  # The app serves the web client from this same origin, so no separate
  # frontend service or CORS config is needed.
  env = {
    DATABASE_URL.valueFrom.secretKeyRef = { name = "puzzle-hunt-postgres-app"; key = "uri"; };
    CLIENT_DOMAIN.value = "https://puzzlehunt.berkeley.mt";
    # Used only for server-side rendering's self-requests (PORT defaults to 9000).
    SERVER_URL.value = "http://127.0.0.1:9000";
  };

  envFrom = [{ secretRef.name = "puzzle-hunt"; }];
in

{
  namespaces.bmt.resources = {
    "postgresql.cnpg.io/v1".Cluster.puzzle-hunt-postgres.spec = {
      instances = 1;
      bootstrap.initdb.database = "puzzlehunt";
      storage.size = "2Gi";
    };

    "apps/v1".Deployment.puzzle-hunt.spec = {
      replicas = 1;
      selector.matchLabels.app = "puzzle-hunt";
      template = {
        metadata.labels.app = "puzzle-hunt";
        spec = {
          # Apply the Drizzle schema before the app starts. Idempotent: on an
          # up-to-date database this is a no-op, and it retries until the
          # Postgres cluster is reachable.
          initContainers.migrate = {
            inherit image env envFrom;
            workingDir = "/app/server";
            command = [ "node" "node_modules/drizzle-kit/bin.cjs" "push" "--config" "drizzle.config.ts" ];
          };

          containers.puzzle-hunt = {
            inherit image env envFrom;
            ports = [{ containerPort = 9000; }];
            resources = {
              limits = { memory = "512Mi"; };
              requests = { cpu = "100m"; memory = "128Mi"; };
            };
          };

          imagePullSecrets = [{ name = "ghcr-auth"; }];
        };
      };
    };

    v1.Service.puzzle-hunt.spec = {
      selector.app = "puzzle-hunt";
      ports = [{
        port = 80;
        targetPort = 9000;
      }];
    };

    # better-auth secret. Real value is managed out-of-band (vault); see the
    # push-vault-secrets app in flake.nix.
    v1.Secret.puzzle-hunt.stringData = {
      BETTER_AUTH_SECRET = "";
    };

    "networking.k8s.io/v1".Ingress.puzzle-hunt-ingress = {
      metadata.annotations."cert-manager.io/cluster-issuer" = "letsencrypt";
      spec = {
        rules = [{
          host = "puzzlehunt.berkeley.mt";
          http.paths = [{
            path = "/";
            pathType = "Prefix";
            backend.service = { name = "puzzle-hunt"; port.number = 80; };
          }];
        }];
        tls = [{
          hosts = [ "puzzlehunt.berkeley.mt" ];
          secretName = "puzzle-hunt-ingress-tls";
        }];
      };
    };
  };
}
