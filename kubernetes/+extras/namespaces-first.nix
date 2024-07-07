{ lib, ... }:

let
  namespacesFirst = { apiVersion, kind, ... }@obj:
    if apiVersion == "v1" && kind == "Namespace" then
      lib.recursiveUpdate
        obj
        { metadata.annotations."argocd.argoproj.io/sync-wave" = "-1"; }
    else obj;
in
{
  transforms = [ namespacesFirst ];
}
