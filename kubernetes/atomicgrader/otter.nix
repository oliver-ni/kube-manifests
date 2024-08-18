{ ... }:

let
  image = "ghcr.io/atomicgrader/otter:latest";
  envFrom = [
    { secretRef.name = "ag-otter"; }
    { configMapRef.name = "ag-otter"; }
  ];
  env = [
    { name = "C_FORCE_ROOT"; value = "true"; }
    { name = "DB_USER"; valueFrom.secretKeyRef = { name = "ag-postgres-app"; key = "username"; }; }
    { name = "DB_PASS"; valueFrom.secretKeyRef = { name = "ag-postgres-app"; key = "password"; }; }
    { name = "DJANGO_DATABASE_URL"; value = "postgres://$(DB_USER):$(DB_PASS)@ag-postgres-rw:5432/atomicgrader"; }
    { name = "RMQ_USER"; valueFrom.secretKeyRef = { name = "ag-rabbitmq-default-user"; key = "username"; }; }
    { name = "RMQ_PASS"; valueFrom.secretKeyRef = { name = "ag-rabbitmq-default-user"; key = "password"; }; }
    { name = "RABBITMQ_BROKER_URL"; value = "amqp://$(RMQ_USER):$(RMQ_PASS)@ag-rabbitmq:5672/"; }
  ];
  volumeMounts = [{
    mountPath = "/assets";
    name = "ag-assets";
  }];
in
{
  namespaces.atomicgrader.resources = {
    v1.ConfigMap.ag-otter.data = {
      DJANGO_SETTINGS_MODULE = "config.settings.prod";
      DJANGO_DEBUG = "False";
      DJANGO_MEDIA_ROOT = "/assets/media/";
      DJANGO_STATIC_ROOT = "/assets/static/";
      DJANGO_ADMIN_URL = "admin";
      DJANGO_ADMIN_NAME = "Oliver Ni";
      DJANGO_ADMIN_EMAIL = "oliver.ni@gmail.com";
      DJANGO_SERVER_EMAIL = "oliver.ni@gmail.com";
      DJANGO_DEFAULT_FROM_EMAIL = "oliver.ni@gmail.com";
      DJANGO_ALLOWED_HOSTS = "localhost,127.0.0.1,ag.poketwo.io";
      EMAIL_URL = "smtp+tls://atomicgrader@gmail.com:PASSWORDHERE@smtp.gmail.com:587";
    };

    v1.Secret.ag-otter.stringData = {
      DJANGO_SECRET_KEY = "";
      DJANGO_JWT_SIGNING_KEY = "";
    };

    "apps/v1".Deployment.ag-otter.spec = {
      selector.matchLabels.app = "ag-otter";
      template = {
        metadata.labels.app = "ag-otter";
        spec = {
          containers = [{
            inherit image env envFrom volumeMounts;
            name = "otter";
            ports = [{ containerPort = 8000; }];
            resources = {
              limits = { memory = "4Gi"; };
              requests = { cpu = "50m"; memory = "1Gi"; };
            };
          }];

          initContainers = [
            {
              inherit image env envFrom volumeMounts;
              name = "migrate";
              command = [ "python" "manage.py" "migrate" ];
            }
            {
              inherit image env envFrom volumeMounts;
              name = "collectstatic";
              command = [ "python" "manage.py" "collectstatic" "--no-input" ];
            }
          ];

          volumes = [{
            name = "ag-assets";
            persistentVolumeClaim.claimName = "ag-assets";
          }];

          imagePullSecrets = [{ name = "ghcr-auth"; }];
        };
      };
    };

    "apps/v1".Deployment.ag-otter-worker.spec = {
      selector.matchLabels.app = "ag-otter-worker";
      template = {
        metadata.labels.app = "ag-otter-worker";
        spec = {
          containers = [{
            inherit image env envFrom volumeMounts;
            name = "otter-worker";
            command = [ "celery" "-A" "config" "worker" "-l" "info" "--concurrency" "1" ];
            resources = {
              limits = { memory = "8Gi"; };
              requests = { cpu = "50m"; memory = "1Gi"; };
            };
          }];
          volumes = [{
            name = "ag-assets";
            persistentVolumeClaim.claimName = "ag-assets";
          }];
          imagePullSecrets = [{ name = "ghcr-auth"; }];
        };
      };
    };

    v1.Service.ag-otter.spec = {
      selector.app = "ag-otter";
      ports = [{ port = 80; targetPort = 8000; }];
    };
  };
}
