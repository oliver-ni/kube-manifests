{ ... }:

{
  namespaces.guts.resources = {
    v1.Secret.guts-scoreboard-auth = {
      type = "kubernetes.io/dockerconfigjson";
      stringData.".dockerconfigjson" = "";
    };
  };
}
