{ ... }:

{
  namespaces.guts.resources = {
    v1.ServiceAccount.landrew = { };

    "rbac.authorization.k8s.io/v1".RoleBinding.landrew = {
      subjects = [{
        kind = "ServiceAccount";
        name = "landrew";
      }];
      roleRef = {
        kind = "ClusterRole";
        name = "admin";
        apiGroup = "rbac.authorization.k8s.io";
      };
    };

    "rbac.authorization.k8s.io/v1".ClusterRoleBinding.landrew = {
      subjects = [{
        kind = "ServiceAccount";
        name = "landrew";
        namespace = "guts";
      }];
      roleRef = {
        kind = "ClusterRole";
        name = "view";
        apiGroup = "rbac.authorization.k8s.io";
      };
    };
  };
}
