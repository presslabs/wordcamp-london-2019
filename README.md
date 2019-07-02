# WordCamp London 2019 Demo

## Prerequisites

#### Two kubernetes clusters:
1. A local kubernetes cluster for local development (eg. Docker for Desktop)
2. A remote kubernetes for production (eg. Google Kubernetes Engine)

#### Local toolchain:
1. PHP >= 7.2
2. [composer](https://getcomposer.org)
3. [wp-cli](https://wp-cli.org)
4. [helm](https://helm.sh)
5. [skafofld](https://skaffold.dev)

## Step 1a: Install stack on the local cluster

#### Install helm's tiller
```console
$ kubectl --namespace kube-system create sa tiller

$ kubectl create clusterrolebinding tiller \
    --clusterrole cluster-admin \
    --serviceaccount=kube-system:tiller

$ helm init --service-account tiller \
    --history-max 10 \
    --override 'spec.template.spec.containers[0].command'='{/tiller,--storage=secret}' \
    --wait
```

#### Install the Presslabs Stack on the local cluster
```console
$ kubectl create ns presslabs-stack

$ kubectl label namespace presslabs-stack certmanager.k8s.io/disable-validation=true

$ helm repo add presslabs https://presslabs.github.io/charts

$ helm repo update

$ helm install -n stack presslabs/stack --namespace presslabs-stack \
    -f https://raw.githubusercontent.com/presslabs/stack/master/presets/minikube.yaml
```

#### Wait for the stack to come online
For that you need to run:

```
$ kubectl -n presslabs-stack get pod
```

And wait until all pods status is either `Running` or `Completed`.

## Step 1b: Create the production cluster and install the Presslabs Stack on it

#### Create the cluster and worker node pools get the cluster credentials
```console
$ gcloud container clusters create --region=europe-west2 \
    --node-locations europe-west2-a,europe-west2-b \
    --machine-type=n1-standard-2 --num-nodes 1 \
    --node-labels=node-role.kubernetes.io/presslabs-sys= \
    --node-taints=CriticalAddonsOnly=true:PreferNoSchedule \
    --enable-ip-alias wclondon-2019

$ gcloud container node-pools create stack-workers-1 --cluster=wclondon-2019 --region=europe-west2 \
    --machine-type=n1-standard-2 --num-nodes 1 \
    --node-labels=node-role.kubernetes.io/wordpress=,node-role.kubernetes.io/database=

$ gcloud container clusters get-credentials --region europe-west2 wclondon-2019
```

### Make sure that your kubeconfig context is the one from production cluster
```console
$ kubectl config get-contexts
```

## Step 1c: Install the stack onto the production cluster
#### Install helm's tiller
```console
$ kubectl --namespace kube-system create sa tiller

$ kubectl create clusterrolebinding tiller \
    --clusterrole cluster-admin \
    --serviceaccount=kube-system:tiller

$ helm init --service-account tiller \
    --history-max 10 \
    --override 'spec.template.spec.containers[0].command'='{/tiller,--storage=secret}' \
    --wait
```

#### Install the Presslabs Stack
```console
$ kubectl create ns presslabs-stack

$ kubectl label namespace presslabs-stack certmanager.k8s.io/disable-validation=true

$ helm repo add presslabs https://presslabs.github.io/charts

$ helm repo update

$ helm install -n stack presslabs/stack --namespace presslabs-stack \
    --set letsencrypt.enabled=true,letsencrypt.email=YOUR_LETS_ENCRYPT_ACCOUNT_EMAIL
    -f https://raw.githubusercontent.com/presslabs/stack/master/presets/gke.yaml
```

#### Wait for the stack to come online
For that you need to run:

```
$ kubectl -n presslabs-stack get pod
```

And wait until all pods status is either `Running` or `Completed`.

#### Switch the context back to the Docker for Desktop cluster
```console
$ kubectl config use-context docker-desktop
```

## Step 2: Create a roots.io Bedrock project

#### Create the project
```console
$ composer create-project roots/bedrock wclondon-2019

$ cd wclondon-2019
```

#### Use the Presslabs Stack WordPress Runtime
```console
composer remove roots/wordpress
composer require presslabs-stack/wordpress ^5.2
docker pull quay.io/presslabs/wordpress-runtime:5.2-7.3.4-latest
```

Before proceeding make note of:
1. The docker repository you are going to publish images to
2. Make note of you production cluster context

``` Console
wp stack init
```

#### Initialize git for version control
```console
git init
git add .
git commit -m "Initial commit"
```

## Step 3: Install some plugins
```console
composer require wpackagist-plugin/debug-bar rarst/laps
```

## Step 4: Launch the local dev environment
```console
skaffold dev
```

## Step 5: Deploy the container to production

**Important** You need to switch to the production kubernetes context (the one
from step 2) before deploying.


```console
kubectl config use-context MY_PROD_CONTEXT

skaffold deploy
```

