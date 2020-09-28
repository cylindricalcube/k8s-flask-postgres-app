# k8s-flask-postgres-app

This a project completed for an SRE challenge.

### Project
The goal was to have a ToDo list Flask app running on K8s behind a load balancer, talking to a postgres master database node configured with streaming replication to a replica database node, also on K8s.

### Development Environment
For a development environment I used the bundled Kubernetes installation with Docker Desktop, developed on a Windows PC using WSL 2 using a Debian distribution. I generally use a Macbook Pro for development but it is getting very old and I do not trust the HDD in it. 

This was my first time using WSL 2 and I found it to be an excellent experience compared to Cygwin hacking and package management nightmares. Performance was ok, but I found Docker builds to be very slow. Maybe I am missing some configuration.

### Infrastructure Code

Tools used: [Terraform 0.12](https://www.terraform.io/)

I briefly investigated using 0.13 (latest at the time) but the additional hassle of provider repositories needing explicit paths seemed like a burden that would cut into my setup time.

Because I am predominantly experienced with AWS at the time completed and this challenge was to be deployed on GCP, as well as the short time window for completion, I had to rely heavily on examples found online. 

I still wanted to run a production grade setup but did not have time to deeply learn all of the network settings and primitives/resources on offer from GCP. Having used a few Gruntwork products and admiring their in-depth and boundary pushing code I leaned on them for examples.

Most of the terraform code is adapted in one way or another from the modules found in this repo: https://github.com/gruntwork-io/terraform-google-gke/. Thank you [Gruntwork](https://www.gruntwork.io) for your excellent work as always.

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