{ ... }:

{
  namespaces.musa = {
    resources.v1.ConfigMap.minecraft-server.data = {
      EULA = "TRUE";
      TYPE = "PAPER";
      VERSION = "1.21";
      MEMORY = "6G";
      MOTD = "MUSA";
      DIFFICULTY = "normal";
      OPS = "Organically,unknownh_";
      MAX_PLAYERS = "50";
      SPAWN_PROTECTION = "0";
      MODE = "survival";
    };

    resources.v1.PersistentVolumeClaim.minecraft-data.spec = {
      accessModes = [ "ReadWriteOnce" ];
      resources.requests.storage = "64Gi";
    };

    resources.v1.Service.minecraft-server.spec = {
      type = "LoadBalancer";
      selector.app = "minecraft-server";
      ports = [{ port = 25565; }];
    };

    resources."apps/v1".StatefulSet.minecraft-server.spec = {
      replicas = 1;
      selector.matchLabels.app = "minecraft-server";
      serviceName = "minecraft-server";
      template = {
        metadata.labels.app = "minecraft-server";
        spec = {
          volumes = [{
            name = "minecraft-data";
            persistentVolumeClaim.claimName = "minecraft-data";
          }];
          containers = [{
            name = "minecraft-server";
            image = "itzg/minecraft-server:latest";
            resources = {
              limits = { memory = "8Gi"; };
              requests = { cpu = "100m"; memory = "8Gi"; };
            };
            envFrom = [{ configMapRef = { name = "minecraft-server"; }; }];
            ports = [{ containerPort = 25565; name = "minecraft"; }];
            volumeMounts = [{ name = "minecraft-data"; mountPath = "/data"; }];
            readinessProbe = {
              exec.command = [ "mcstatus" "127.0.0.1" "ping" ];
              initialDelaySeconds = 30;
              periodSeconds = 30;
            };
            livenessProbe = {
              exec.command = [ "mcstatus" "127.0.0.1" "ping" ];
              initialDelaySeconds = 30;
              periodSeconds = 30;
            };
          }];
        };
      };
    };

    resources."cilium.io/v2".CiliumNetworkPolicy.allow-ingress-to-minecraft.spec = {
      endpointSelector.matchLabels.app = "minecraft-server";
      ingress = [{ fromEntities = [ "all" ]; }];
    };
  };
}
