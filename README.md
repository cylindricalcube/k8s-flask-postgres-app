# k8s-flask-postgres-app

This a project completed for a challenge, I had no knowledge of Flask prior to creating this so please forgive if anything is suboptimal in my setup of the framework.

The goal was to have a TODO list Flask app running on K8s behind a load balancer, talking to a postgres master database node configured with streaming replication to a replica database node, also on K8s.

For a development environment I used the bundled Kubernetes installation with Docker Desktop, developed on a Windows PC using WSL 2.

## Requirements

### Environment Variables

`TD_PROJECT_ROOT` must be set to the root directory of this Git repository in order for the scripts to work.

eg. 
```
export TD_PROJECT_ROOT="/dev/k8s-flask-postgres-app"
```
---
### Software Requirements

You will need:
- [Docker](https://hub.docker.com)
- [Helmv3](https://helm.sh)
- [sops](https://github.com/mozilla/sops/releases)
- [kubectl 1.18](https://kubernetes.io/docs/tasks/tools/install-kubectl/)

## Build 

```
./scripts/build
```

## Test

To test you can:

```
./scripts/test
```

## Deploy

### Script Assumptions
You must have a `kubeconfig` context with a matching name to one of the envs. To deploy to `dev` you must have a context named `dev`.

eg.
```
./scripts/deploy -c todoozle -e dev
```
Will deploy the `todoozle` chart files using `kubectl apply --context dev -f <files>`.

### Deploying and updating components of the stack

To deploy this project from scratch and test that it is running you can run:

```
CHART=<chart> DEPLOY_ENV=<env> ./scripts/deploy
```
or
```
./scripts/deploy -c <chart> -e <env>
```

### Deploying the entire stack

To deploy this project from scratch and test that it is running you can run:

```
./scripts/deploy_all -e <env> 
```
or
```
DEPLOY_ENV=<env> ./scripts/deploy_all
```