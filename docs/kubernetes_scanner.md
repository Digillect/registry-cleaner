# Kubernetes Scanner details

Kubernetes scanner scans resources of all kinds that contains a PodTemplateSpec in
their definition (except those that has been specified in configuration as ignored)
in all namespaces and extracts image references from `containers` and `initContainers`
sections.

## Keep Alive images

Sometimes you have to "keep" an image even if it is not directly referenced by any
of the resources, for example when such image is used by Helm hook's job. To tell scanner
that certain images should be treated as active you can create one or more ConfigMaps
with `registry-cleaner: keep-alive` label in metadata. Every key in the data section of
such ConfigMap will be treated as newline separated list of image names:

```yaml
kind: ConfigMap
apiVersion: v1
metadata:
  name: registry-cleaner-keep-alive
  namespace: example-project
  labels:
    registry-cleaner: keep-alive
data:
  keep-alive: |
    registry.example.org/example-project/install-hook:33b1e1c219d131abbebdddac65329925a9645fa4
    registry.example.org/example-project/upgrade-hook:33b1e1c219d131abbebdddac65329925a9645fa4
```

