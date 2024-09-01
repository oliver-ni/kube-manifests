{ transpire, ... }:

let
  env = [
    { name = "URL"; value = "https://docs.berkeley.mt"; }
    { name = "PORT"; value = "3000"; }

    { name = "REDIS_PASS"; valueFrom.secretKeyRef = { name = "redis"; key = "redis-password"; }; }
    { name = "REDIS_URL"; value = "redis://:$(REDIS_PASS)@redis-master:6379/?family=6"; }

    { name = "DB_USER"; valueFrom.secretKeyRef = { name = "postgres-app"; key = "username"; }; }
    { name = "DB_PASS"; valueFrom.secretKeyRef = { name = "postgres-app"; key = "password"; }; }
    { name = "DATABASE_URL"; value = "postgres://$(DB_USER):$(DB_PASS)@postgres-rw:5432/outline"; }

    { name = "AWS_ACCESS_KEY_ID"; valueFrom.secretKeyRef = { name = "outline-bucket"; key = "AWS_ACCESS_KEY_ID"; }; }
    { name = "AWS_SECRET_ACCESS_KEY"; valueFrom.secretKeyRef = { name = "outline-bucket"; key = "AWS_SECRET_ACCESS_KEY"; }; }
    { name = "AWS_S3_UPLOAD_BUCKET_NAME"; valueFrom.configMapKeyRef = { name = "outline-bucket"; key = "BUCKET_NAME"; }; }
    { name = "AWS_S3_UPLOAD_BUCKET_URL"; value = "https://rgw.hfym.co"; }
    { name = "AWS_S3_ACL"; value = "private"; }

    { name = "GOOGLE_CLIENT_ID"; value = "799809453242-iesp4onlaje1hu5h97iq313h6f06mjuo.apps.googleusercontent.com"; }

    { name = "SMTP_HOST"; value = "smtp.resend.com"; }
    { name = "SMTP_PORT"; value = "465"; }
    { name = "SMTP_USERNAME"; value = "resend"; }
    { name = "SMTP_PASSWORD"; valueFrom.secretKeyRef = { name = "outline"; key = "RESEND_API_KEY"; }; }
    { name = "SMTP_FROM_EMAIL"; value = "noreply@berkeley.mt"; }
  ];

  envFrom = [{ secretRef.name = "outline"; }];
in
{
  namespaces.bmt-outline = {
    helmReleases.redis = {
      chart = transpire.fetchFromHelm {
        repo = "https://charts.bitnami.com/bitnami";
        name = "redis";
        version = "19.6.1";
        sha256 = "z7M/oHv2x9LVaMaPXk5KfYYqZs7m7+PmLxnKjL0Thxs=";
      };

      values = {
        architecture = "standalone";
        master.persistence.size = "1Gi";
        metrics.enabled = true;
      };
    };

    resources."apps/v1".Deployment.outline.spec = {
      replicas = 1;
      selector.matchLabels.app = "outline";
      template = {
        metadata.labels.app = "outline";
        spec = {
          containers = [{
            name = "outline";
            image = "outlinewiki/outline:0.75.0";
            ports = [{ containerPort = 3000; }];
            resources = {
              limits = { memory = "4Gi"; };
              requests = { memory = "1Gi"; cpu = "100m"; };
            };
            inherit env envFrom;
          }];
        };
      };
    };

    resources."networking.k8s.io/v1".Ingress.outline-ingress = {
      metadata.annotations."cert-manager.io/cluster-issuer" = "letsencrypt";
      spec = {
        rules = [{
          host = "docs.berkeley.mt";
          http.paths = [{
            path = "/";
            pathType = "Prefix";
            backend.service = { name = "outline"; port.number = 80; };
          }];
        }];
        tls = [{
          hosts = [ "docs.berkeley.mt" ];
          secretName = "outline-ingress-tls";
        }];
      };
    };

    resources."postgresql.cnpg.io/v1".Cluster.postgres.spec = {
      instances = 3;
      bootstrap.initdb.database = "outline";
      storage.size = "8Gi";
    };

    resources."objectbucket.io/v1alpha1".ObjectBucketClaim.outline-bucket.spec = {
      generateBucketName = "outline";
      storageClassName = "rgw-nvme";
    };

    resources.v1.Service.outline.spec = {
      selector = { app = "outline"; };
      ports = [{ port = 80; targetPort = 3000; }];
    };

    resources.v1.Secret.outline.stringData = {
      SECRET_KEY = "";
      UTILS_SECRET = "";
      GOOGLE_CLIENT_SECRET = "";
      RESEND_API_KEY = "";
    };
  };
}

# To set up CORS for S3 bucket:
# $ s3cmd setcors cors.xml s3://outline-bucket

# <CORSConfiguration>
# <CORSRule>
#     <AllowedOrigin>https://docs.berkeley.mt</AllowedOrigin>
#     <AllowedMethod>PUT</AllowedMethod>
#     <AllowedMethod>POST</AllowedMethod>
#     <AllowedHeader>*</AllowedHeader>
# </CORSRule>
# <CORSRule>
#     <AllowedOrigin>*</AllowedOrigin>
#     <AllowedMethod>GET</AllowedMethod>
#     <AllowedHeader>*</AllowedHeader>
# </CORSRule>
# </CORSConfiguration>
