{ ... }:

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
in
{
  namespaces.users.resources = {
    v1.ServiceAccount.landrew = { };
    v1.ServiceAccount.toraora = { };

    "rbac.authorization.k8s.io/v1".ClusterRoleBinding.landrew = roleBinding "landrew" "view";
    "rbac.authorization.k8s.io/v1".ClusterRoleBinding.toraora = roleBinding "toraora" "view";
  };

  namespaces.bmt.resources = {
    "rbac.authorization.k8s.io/v1".RoleBinding.landrew = roleBinding "landrew" "admin";
  };

  namespaces.atomicgrader.resources = {
    "rbac.authorization.k8s.io/v1".RoleBinding.landrew = roleBinding "landrew" "admin";
    "rbac.authorization.k8s.io/v1".RoleBinding.toraora = roleBinding "toraora" "admin";
  };
}
