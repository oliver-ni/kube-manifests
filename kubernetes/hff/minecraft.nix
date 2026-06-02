{ ... }:

{
  namespaces.hff.resources = {
    "apps/v1".Deployment.minecraft.spec = {
      replicas = 1;
      # RWO volume can only be mounted by one pod at a time
      strategy.type = "Recreate";
      selector.matchLabels.app = "minecraft";
      template = {
        metadata.labels.app = "minecraft";
        spec = {
          containers.minecraft = {
            image = "itzg/minecraft-server:latest";
            ports = [{ containerPort = 25565; }];
            env = {
              EULA.value = "TRUE";
              TYPE.value = "PAPER";
              VERSION.value = "1.21.11";
              # JVM heap; kept below the container limit to leave headroom
              # for off-heap memory, metaspace, etc.
              MEMORY.value = "3G";
              ENABLE_WHITELIST.value = "TRUE";
              ENFORCE_WHITELIST.value = "TRUE";
              # Authoritative whitelist: reconciles server whitelist to exactly
              # this list (removes anyone not listed here).
              OVERRIDE_WHITELIST.value = "TRUE";
              WHITELIST.value = "gojosleftsock69,zinn024,wnsgml7,mcparadox,Organically";
            };
            resources = {
              limits = { memory = "4Gi"; };
              requests = { cpu = "500m"; memory = "1Gi"; };
            };
            volumeMounts = [{
              name = "minecraft-data";
              mountPath = "/data";
            }];
            readinessProbe = {
              exec.command = [ "mc-health" ];
              initialDelaySeconds = 30;
              periodSeconds = 10;
              failureThreshold = 18;
            };
            livenessProbe = {
              exec.command = [ "mc-health" ];
              initialDelaySeconds = 120;
              periodSeconds = 30;
              failureThreshold = 6;
            };
          };
          volumes.minecraft-data = {
            persistentVolumeClaim.claimName = "minecraft-data";
          };
        };
      };
    };

    v1.PersistentVolumeClaim.minecraft-data.spec = {
      accessModes = [ "ReadWriteOnce" ];
      resources.requests.storage = "16Gi";
    };

    v1.Service.minecraft.spec = {
      type = "LoadBalancer";
      selector.app = "minecraft";
      ports = [{
        name = "minecraft";
        port = 25565;
        targetPort = 25565;
        protocol = "TCP";
      }];
    };

    "cilium.io/v2".CiliumNetworkPolicy.allow-ingress-to-minecraft.spec = {
      endpointSelector.matchLabels.app = "minecraft";
      ingress = [{ fromEntities = [ "all" ]; }];
    };
  };
}
