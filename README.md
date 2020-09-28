# k8s-flask-postgres-app

This a project completed for an SRE challenge.

## Project
The goal was to have a ToDo list Flask app running on K8s behind a load balancer, talking to a postgres master database node configured with streaming replication to a replica database node, also on K8s.

## Development Environment
For a development environment I used the bundled Kubernetes installation with Docker Desktop, developed on a Windows PC using WSL 2 using a Debian distribution. I generally use a Macbook Pro for development but it is getting very old and I do not trust the HDD in it. 

This was my first time using WSL 2 and I found it to be an excellent experience compared to Cygwin hacking and package management nightmares. Performance was ok, but I found Docker builds to be very slow. Maybe I am missing some configuration.

## Infrastructure Code

Tools used: [Terraform 0.12](https://www.terraform.io/)

I briefly investigated using 0.13 (latest at the time) but the additional hassle of provider repositories needing explicit paths seemed like a burden that would cut into my setup time.

Because I am predominantly experienced with AWS at the time completed and this challenge was to be deployed on GCP, as well as the short time window for completion, I had to rely heavily on examples found online. 

I still wanted to run a production grade setup but did not have time to deeply learn all of the network settings and primitives/resources on offer from GCP. Having used a few Gruntwork products and admiring their in-depth and boundary pushing code I leaned on them for examples.

Most of the terraform code is adapted in one way or another from the modules found in this repo: https://github.com/gruntwork-io/terraform-google-gke/. Thank you [Gruntwork](https://www.gruntwork.io) for your excellent work as always.

## Database

PostgreSQL is deployed with streaming replication enabled. Having never run PostgreSQL this was an interesting challenge and took me a little longer than I would have liked. Settings may be suboptimal but replication is functional across single main and replica pods. 

Settings in the main instance that were needed:
`postgresql.conf`
```
    #Replication Settings
    wal_level = replica
    max_wal_senders = 2
    max_replication_slots = 2
    synchronous_commit = off
```
`pg_hba.conf`
```
host    replication     repuser         0.0.0.0/0               scram-sha-256
```

## Load Balancer Issues

I had an issue when attempting to lock down the service to my personal IP address. GKE has a built-in ingress controller, so when I created an Ingress object and attached it to the Todoozle Service it automatically created a publically accessible load balancer. This appeared to make my firewall rules defined in terraform useless. 

After reading plenty of documentation and finding nothing, I stumbled upon a user who simply defined "Load Balancer Source Ranges" from within Kubernetes on the Service object. 

```
spec:
  ports:
  - name: http
    port: 80
    protocol: TCP
    targetPort: 5000
  selector:
    app: todoozle
  {{- if eq .Values.env "dev" }}
  type: ClusterIP
  {{- else }}
  type: LoadBalancer
  loadBalancerSourceRanges:
  - <my_ip>/32
```

Because of that I now have a Service object in non-dev envs of type: LoadBalancer which deploys a Layer 4 load balancer direct to the Todoozle Flask app containers. This will have to do for now.

## Future Work

Some things that I didn't have time to do but would be necessary in a production (or even staging) setup.

- Sanitization of app input strings
- Terraform code for the GCP KMS key and role mappings for IAM decrypt access to the key
- Full automated startup of the stack on a clean environment for builds
- Tests
    - Terraform tests to ensure nothing has broken when making changes
    - Python Unit tests
    - Python end to end tests to ensure everything is working post-rollout (or during)
- Full CI/CD setup instead of manual deployments to environments with version tracking between environments.
- ConfigMaps should probably be immutable with SHAs added to their names for proper updates and fault tolerance
- Better health checks and readiness checks for app/db
- PostgreSQL
    - Tune settings on the replication and other
    - Node affinity settings 
    - Failover settings and management (currently replication is only possible one way)


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
- [kubectl 1.17](https://kubernetes.io/docs/tasks/tools/install-kubectl/)

## Build 

```
./scripts/build
```

## Deploy

### Script Assumptions
You must have a `kubeconfig` context with a matching name to one of the envs. To deploy to `dev` you must have a context named `dev`.

eg.
```
./scripts/deploy -c todoozle -e dev
```
Will deploy the `todoozle` chart files using `kubectl apply --context dev -f <files>`.

### Infrastucture

To create the infrastructure you must have the gCloud SDK setup
and Terraform v0.12 installed, then:

```
# From repo root
cd terraform
terraform init
terraform plan -var-file terraform.tfvars -var-file vars/<env>/terraform.tfvars
# If that looks good and passes:
terraform apply -var-file terraform.tfvars -var-file vars/<env>/terraform.tfvars
```

### Secrets
When adding a new env's secrets:

Create a sops kms key and use it to encrypt the secrets.yaml files.
```
gcloud kms keyrings create sops --location global
gcloud kms keys create "todoozle-<env>-sops-key" --location global --keyring sops --purpose encryption
gcloud kms keys list --location global --keyring sops

# Now you can encrypt your config files
sops --encrypt --gcp-kms projects/<project>/locations/global/keyRings/sops/cryptoKeys/todoozle-<env>-sops-key "config/<env>/secrets.yaml" > "config/<env>/secrets.yaml"
```

### Deploying and updating components of the stack

To deploy and update stack components:

```
CHART=<chart> DEPLOY_ENV=<env> ./scripts/deploy
```
or
```
./scripts/deploy -c <chart> -e <env>
```

### Deploying the entire stack

To deploy the entire stack from scratch follow these instructions:


If you're using a dev env you will probably need ingress-nginx installed:
```
# Create the ingress-nginx namespace
kubectl create namespace ingress-nginx 

# Install the ingress controller
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm install --namespace ingress-nginx ingress-nginx ingress-nginx/ingress-nginx
```

#### Database
```
# Deploy the main DB
./scripts/deploy -e <env> -c postgres-main

# Check that the DB is running
kubectl describe pods/postgres-main-0
kubectl logs pods/postgres-main-0

# Now you need to create the user for replication
kubectl exec -it pods/postgres-main -- bash
# from within container
su - postgres
psql -U todoozle
> SET password_encryption = 'scram-sha-256';
> CREATE ROLE repuser WITH REPLICATION PASSWORD '<repuser_password>' LOGIN;
> SELECT * FROM pg_create_physical_replication_slot('replica_1_slot');
>\q
exit
exit

# Deploy migrations
./scripts/deploy -e <env> -c todoozle-migrate

# Check migrations were successful
kubectl describe job/todoozle-migrate
```

#### Flask App and Load Balancer
Now is a good time to add your IP address to the `loadBalancerSourceRanges` list in secrets.yaml for your `<env>` otherwise you won't be able to reach the service.
```
# Deploy Flask app
./scripts/deploy -e <env> -c todoozle

# Check app is running
kubectl get deployment/todoozle

# Check that the load balancer was created for the Service
kubectl get svc/todoozle

# Check the IP address assigned to the created load balancer
gcloud compute forwarding-rules list

# Test service is running by navigating to that IP in the browser, or by
curl http://<LB_ip>
```
