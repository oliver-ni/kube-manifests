{ ... }:

{
  namespaces.tph-2024-staging.resources = {
    "postgresql.cnpg.io/v1".Cluster.tph-postgres.spec = {
      instances = 3;
      imageName = "ghcr.io/cloudnative-pg/postgresql:16";
      bootstrap.initdb.database = "tph";
      storage.size = "8Gi";
    };

    "postgresql.cnpg.io/v1".Pooler.tph-pgbouncer.spec = {
      cluster.name = "tph-postgres";
      instances = 3;
      type = "rw";
      pgbouncer.parameters = {
        max_client_conn = "2000";
        default_pool_size = "2000";
      };
    };
  };
}
