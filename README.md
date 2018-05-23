# Registry Cleaner

Registry Cleaner is a tool to take care of Docker images that were created
and published as a result of CI/CD process and are not used anymore.

## Documentation

- [How the Registry Cleaner works](docs/algorithm.md)
- [Configuring Registry Cleaner](docs/configuration.md)
- [Kubernetes Scanner details](docs/kubernetes_scanner.md)

## Installation and usage

First of all you have to prepare a configuration file (see
[Configuring Registry Cleaner](docs/configuration.md)) that describes
required registries and scanners. You can put it anywhere in case of using Docker
or you'll need to change an existing one in the `deploy` folder in case of
Kubernetes installation.

### Using Docker

To run the latest version of Registry Cleaner:

```bash
docker run --rm -it \
-v <path to config file>:/app/config.yaml \
-v <path to home directory>/.kube/config:/root/kube/config \
digillect/registry-cleaner
```

### Using deployment to Kubernetes Cluster

The Helm chart to deploy Registry Cleaner to Kubernetes cluster can be found in
the `deploy` folder.

To deploy latest version of Registry Cleaner:

```bash
helm upgrade --install registry-cleaner deploy
```

To deploy a specified version of Registry Cleaner:

```bash
helm upgrade --install --set imageTag=<tag> registry-cleaner deploy
```

By default Registry Cleaner spawns every night at 2 am. To change cleaning schedule
pass `--set schedule="<schedule>"` parameter, where `<schedule>` is a Cron schedule
specification.

#### RBAC

RBAC support is enabled by default and deployment will create all required resources. To disable
RBAC (for old clusters) just add `--set rbac=false` to `helm` command.

## License

This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details
