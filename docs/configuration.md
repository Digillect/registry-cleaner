# Configuring Registry Cleaner

Registry Cleaner configuration is stored in a YAML file, usually located in the
same directory as a startup script, but can be placed anywhere else. The full
path and name of the configuration file is supplied with `CONFIG_FILE` environment
variable.

## Configuration example

Example of the configuration file will be discussed in details in the following
sections of this document.

```yaml
registries:
  registry.example.org:
    kind: nexus
    url: http://registry.example.org
    repository: docker-hosted
    username: jdoe
    passwordFrom: REGISTRY_PASSWORD
    ignore:
      - ignored-project/.+
      - project/ignored-project-image
scanners:
  - kind: kubernetes
    ignore:
      - ReplicaSet
 ```

## Registries

### All kind of registries

#### kind

Specifies the kind of the registry. At the moment the only allowed values are `docker` and `nexus`.
If the `kind` option is not set then `docker` is assumed.

#### ignore

Array of regular expressions that are used to ignore (not include into the consideration)
images of the registry.

### Docker registries

#### url

URL of the Nexus API endpoint.

#### urlFrom

Name of the environment variable to get an actual url from.

#### username

Username to authenticate to the Nexus server.

#### password

Password to authenticate to the Nexus server.

#### usernameFrom

Name of the environment variable to get an actual username from.

#### passwordFrom

Name of the environment variable to get an actual password from.

### Nexus registries

#### url

#### urlFrom

Name of the environment variable to get an actual url from.

URL of the Nexus API endpoint.

#### repository

Name of the Nexus repository that holds images of the registry.

#### repositoryFrom

Name of the environment variable to get an actual repository name from.

#### username

Username to authenticate to the Nexus server.

#### password

Password to authenticate to the Nexus server.

#### usernameFrom

Name of the environment variable to get an actual username from.

#### passwordFrom

Name of the environment variable to get an actual password from.

## Scanners

### All kind of scanners

#### kind

The kind of the scanner. At the moment the only allowed value is `kubernetes`.

### Kubernetes scanners

#### ignore

Array of Kubernetes resource kinds to ignore. Allowed values are:

- `CronJob`
- `DaemonSet`
- `Deployment`
- `Pod`
- `ReplicaSet`
- `ReplicationController`
- `StatefulSet`
