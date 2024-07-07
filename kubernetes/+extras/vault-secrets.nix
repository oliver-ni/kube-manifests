{ ... }:

let
  useVaultSecrets = { apiVersion, kind, metadata, ... }@obj:
    if apiVersion == "v1" && kind == "Secret" then
      {
        inherit metadata;
        apiVersion = "secrets.hashicorp.com/v1beta1";
        kind = "VaultStaticSecret";
        spec = {
          type = "kv-v2";
          mount = "hfym-ds";
          path = "${metadata.namespace}/${metadata.name}";
          destination = {
            inherit (metadata) name;
            create = true;
            type = obj.type or "Opaque";
          };
        };
      }
    else obj;
in
{
  transforms = [ useVaultSecrets ];
}
