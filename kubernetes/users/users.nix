{ lib, ... }:

let
  roleBinding = saName: roleName: {
    subjects = [{
      kind = "ServiceAccount";
      name = saName;
      namespace = "users";
    }];
    roleRef = {
      kind = "ClusterRole";
      name = roleName;
      apiGroup = "rbac.authorization.k8s.io";
    };
  };

  adminIn = saName: namespaces: lib.genAttrs namespaces (_: {
    resources."rbac.authorization.k8s.io/v1".RoleBinding.${saName} = roleBinding saName "admin";
  });

  bmtNamespaces = [
    "bmt"
    "bmt-auth"
    "bmt-contestdojo-verifier-bot"
    "bmt-discord-bot"
    "bmt-guts-scoreboard"
    "bmt-jirav"
    "bmt-ops-dashboard"
    "bmt-outline"
    "bmt-stickers"
    "bmt-vaultwarden"
    "bmt-webview"
  ];
in
{
  namespaces = lib.mkMerge [
    {
      users.resources = {
        v1.ServiceAccount.iancheung = { };
        v1.ServiceAccount.landrew = { };
        v1.ServiceAccount.toraora = { };

        "rbac.authorization.k8s.io/v1".ClusterRoleBinding.iancheung = roleBinding "iancheung" "view";
        "rbac.authorization.k8s.io/v1".ClusterRoleBinding.landrew = roleBinding "landrew" "view";
        "rbac.authorization.k8s.io/v1".ClusterRoleBinding.toraora = roleBinding "toraora" "view";
      };
    }

    (adminIn "iancheung" bmtNamespaces)
    (adminIn "landrew" [ "atomicgrader" "bmt" ])
    (adminIn "toraora" [ "atomicgrader" "bmt-jirav" "bmt-webview" "icmt-webview" "toraora" ])
  ];
}
