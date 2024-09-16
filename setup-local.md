# Local Setup

## Devcontainer (vscode)

TODO: Ideally we'd use the `Kubectl, Helm, and Kubernetes` feature directly, but it seems to be bugged. Will investigate later again.

```js
{
	"name": "Docker in Docker",
	"image": "mcr.microsoft.com/devcontainers/base:bullseye",
	"features": {
		"ghcr.io/devcontainers/features/docker-in-docker:2": {
			"version": "latest",
			"enableNonRootDocker": "true",
			"moby": "false"
		},
		"ghcr.io/devcontainers/features/go:1": {},
		"ghcr.io/devcontainers/features/rust:1": {}
	}
}
```

### Install Tooling

```bash
# ## Kubectl
# > https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/#install-using-native-package-management
sudo mkdir -p -m 755 /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.31/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
# allow unprivileged APT programs to read this keyring
sudo chmod 644 /etc/apt/keyrings/kubernetes-apt-keyring.gpg
# This overwrites any existing configuration in /etc/apt/sources.list.d/kubernetes.list
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.31/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
# helps tools such as command-not-found to work correctly
sudo chmod 644 /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update && sudo apt-get install -y kubectl

# ## Helm
# > https://helm.sh/docs/intro/install/#from-apt-debianubuntu
curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
sudo apt-get update && sudo apt-get install -y helm

# ## Minikube
# > https://minikube.sigs.k8s.io/docs/start/
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube_latest_amd64.deb
sudo dpkg -i minikube_latest_amd64.deb && rm minikube_latest_amd64.deb
```

## Setup Local Kubernetes Cluster

```bash
# minikube delete
minikube start
# minikube start --memory 20480 --cpus 12
```

## Deployment

```bash
echo; echo "Verifying access to the GKE cluster..."
kubectl get nodes

echo; echo "Installing RabbitMQ Cluster Operator..."
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update
helm install rabbitmq-cluster-operator bitnami/rabbitmq-cluster-operator \
  --version 4.3.14 \
  --namespace rabbitmq-cluster-operator \
  --create-namespace

echo; echo "Installing KEDA..."
helm repo add kedacore https://kedacore.github.io/charts
helm repo update
helm install keda kedacore/keda \
  --version 2.14.2 \
  --namespace keda \
  --create-namespace

echo; echo "Installing Prometheus Operator..."
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm install prometheus-operator prometheus-community/kube-prometheus-stack \
  --version 61.3.1 \
  --namespace kube-prometheus \
  --create-namespace

echo; echo "Installing zk-evm..."
# helm delete zk-evm-worker --namespace zk-evm
helm install zk-evm-worker --namespace zk-evm --create-namespace ./helm
```

List installations and deployments:

```bash
echo; echo "Listing Helm Installations..."
helm list --all --all-namespaces

echo; echo "Listing Kubernetes Deployments..."
kubectl get deployments --all-namespaces

kubectl get pods -n zk-evm
```

To restart deployment:

```bash
kubectl rollout restart deployment zk-evm-worker -n zk-evm
```
