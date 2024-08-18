{ ... }:

{
  namespaces.atomicgrader.resources = {
    "postgresql.cnpg.io/v1".Cluster.ag-postgres.spec = {
      instances = 3;
      bootstrap.initdb.database = "atomicgrader";
      storage.size = "8Gi";
    };

    "rabbitmq.com/v1beta1".RabbitmqCluster.ag-rabbitmq.spec = {
      # image = "docker.io/bitnami/rabbitmq:3.11.10-debian-11-r5";
      replicas = 1;
      resources = {
        limits.memory = "8Gi";
        requests.memory = "1Gi";
      };

      override.statefulSet.spec.template.spec = {
        initContainers = [{
          name = "ipv6-init";
          image = "docker.io/busybox:1.33.1";
          imagePullPolicy = "IfNotPresent";
          volumeMounts = [{ name = "ipv6-cfg"; mountPath = "/ipv6"; }];
          command = [ "sh" "-c" ''echo "{inet6, true}." > /ipv6/erl_inetrc'' ];
        }];
        volumes = [{
          name = "ipv6-cfg";
          emptyDir = { };
        }];
        containers = [{
          name = "rabbitmq";
          env = [
            { name = "RABBITMQ_SERVER_ADDITIONAL_ERL_ARGS"; value = "-kernel inetrc '/ipv6/erl_inetrc' -proto_dist inet6_tcp"; }
            { name = "RABBITMQ_CTL_ERL_ARGS"; value = "-proto_dist inet6_tcp"; }
          ];
          volumeMounts = [{ name = "ipv6-cfg"; mountPath = "/ipv6"; }];
        }];
      };
    };
  };
}
