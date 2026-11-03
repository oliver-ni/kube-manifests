{ ... }:

{
  # Packages created by the first push from CI are private. Make them public,
  # or give the namespace an image pull secret.
  images.registry = "ghcr.io/oliver-ni";
}
