# How the Registry Cleaner works

Standard CI/CD workflow that we use at Actis Wunderman is to produce Docker
image(s) on every push to GIT repository and deploy those images to corporate
Kubernetes cluster for preview, testing, QA and production. As a result a
lot of images that were used once but not needed anymore are sits in the Docker
Registry (we use Nexus) forever, especially when the new project is under intensive
development and push rate is high. To address that issue and clean up unused images
Registry Cleaner (RC) inspects Kubernetes resources, such as Deployments and
Cron Jobs, to detect any images originated in our private registry and then
cleans them up.

By convention, images of the project are grouped under the same prefix, for example
frontend and backend images of project _example_, that are originated from registry
`registry.example.org` will be tagged as `registry.example.org/example-project/frontend:<tag>`
and `registry.example.org/example-project/backend:<tag>`. Usually `<tag>` is a hash
of the GIT commit that triggered CI/CD pipeline, but can be anything (or nothing).

When inspecting Kubernetes resources, RC groups images by registry and then by a prefix.
Any images in registry that has the same prefix as any of the "active" images, but are not
marked as "active" considered "inactive" and will be deleted from registry, unless when
protected by a Keep-Alive configuration (see below).

To illustrate the decision-making algorithm let's imagine that after inspecting Kubernetes
cluster the following images has been marked as "active":

```
registry.example.org/example-project-1/frontend:v2
registry.example.org/example-project-1/backend:v2
registry.example.org/example-project-2/frontend:v1
``` 

At the same time registry `registry.example.org` contains the following images:

```
example-project-1/frontend:v1
example-project-1/frontend:v2
example-project-1/backend:v1
example-project-1/backend:v2
example-project-2/frontend:v1
example-project-2/test-image:latest
```

Registry Cleaner will delete the following images from `registry.example.org`:

```
example-project-1/frontend:v1
example-project-1/backend:v1
example-project-2/test-image:latest
```

Frontend and backend images of version 1 of `example-project-1` will be deleted because
they are not in the list of active versions of the corresponding images and
`example-project-2/test-image:latest` will be deleted because there are no active versions
of that image, but prefix `example-project-2` selected for cleanup due to the
`example-project-2/frontend:v1` image.
