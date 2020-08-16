# cloud-native

Example cloud native solution, using serverless functions on Kubernetes in a public cloud provider.
Includes a command to deploy everything in your own cloud account in an automated fashion. 

### Application

The application in this cloud native example is an OpenFaas function, using [Node.js](https://nodejs.org/).

[OpenFaas](https://www.openfaas.com/) is a framework for serverless functions,
 that can be run on top of Kubernetes.
Functions are packaged, run, and managed as [Docker](https://www.docker.com/) containers.

### Platform

[Kubernetes](https://kubernetes.io/) is the platform used in this example, specifically [OKE](https://docs.cloud.oracle.com/en-us/iaas/Content/ContEng/Concepts/contengoverview.htm). 
OKE is a managed Kubernetes service in OCI.

[Ingress Nginx](https://kubernetes.github.io/ingress-nginx/) is deployed for the publicly accessible ingress to the OpenFaas service,
with [Cert Manager](https://cert-manager.io/) handling the self-signed TLS certificate.
 
[Helm](https://helm.sh/) and [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/) are the main tools used to deploy everything to the Kubernetes cluster.

### Infrastructure

[Oracle Cloud Infrastructure](https://www.oracle.com/cloud/) is a public cloud provider from Oracle, referred to as OCI.
This example uses OCI for all infrastructure, such as networking and OKE,
utilizing the publicly available free trial.

[Terraform](https://www.terraform.io/) is used to define and create all infrastructure, services, and resources used in OCI. 

## Prerequisites

There are a few items that must be configured before deploying this project.
If you do not meet these prerequisites, you will not be able to successfully deploy the project.

### Oracle Cloud account

You must activate a free trial account for Oracle Cloud, or otherwise have an existing paid account.
The free trial offering is valid for 30 days with a $300 credit.
https://www.oracle.com/cloud/free/

If you have an existing OCI account, you must be in the Administrators Group 
or have proper IAM privileges to create all of the resources used by this project.
Resources needed are defined through Terraform [here](tf), 
as well as provisioning a public load balancer through a Kubernetes service.

Your Tenancy OCID and home region need to be provided in an envfile.

Copy `.envfile.tpl` to `.envfile`, and enter your specific information.

Example `.envfile` will look like:
```
TENANCY_OCID=ocid1.tenancy.oc1..aaaa...
HOME_REGION=us-phoenix-1
```

If you need help finding this information, read [this](https://docs.cloud.oracle.com/en-us/iaas/Content/General/Concepts/identifiers.htm).

### Docker

Docker must be installed on the host machine.
The majority of scripts and tooling, including the main creation command, are run through a Docker container locally.
Port `8181` must not be in use, as this is used for automated login to OCI.

### Browser

A modern browser must be available on the host machine.
Most commands in this project will fetch a security token for OCI access.
This is done through a browser-based login flow. 

## Creation

A single command deploys the cloud infrastructure, Kubernetes setup, and application.
This process will likely take 10+ minutes to finish.
If at any point it seems like something may be stuck, do not interrupt or cancel the process.
It is likely waiting on a particular cloud or Kubernetes resource to finish provisioning before moving on.

1. Make sure prerequisites are in place, defined in the previous section.
1. Run `make`.

### steps of creation command

During execution, the command will print messages for every step taken.
Below is an overview of the major things `make` will do:

1. Build a local Docker image to run the actual create script.
The first time this image is built can take a few minutes.
1. You will be prompted to sign in to OCI with a given URL.
Open that URL in your browser and sign in with your OCI account credentials.
When you see the following message, you can return to the command line:
    > Authorization completed! Please close this window and return to your terminal to finish the bootstrap process.
1. Terraform will be applied, creating all OCI resources in the `cloud-native` compartment.
This can take 5+ minutes to complete.
1. The script will wait for the Kubernetes worker nodes to become ready.
This can also take 5+ minutes.
1. Kubernetes resources will be deployed, such as OpenFaas, Ingress-Nginx, and Cert-Manager.
1. The application function will be deployed through the OpenFaas gateway.
1. Public connectivity to the function will be tested.
1. Final instructions will be printed for you to add an entry to your local hosts file,
and how to access the function from your machine.
Read [this](https://support.rackspace.com/how-to/modify-your-hosts-file/) if you are unfamiliar with how to do this.
 
When `make` has finished and you followed the final printed steps, the application can be accessed at https://gateway.example/function/app.
This demonstration uses a self-signed certificate, so you will see an insecure warning message from your browser.
This is expected; allow a security exception to continue.

The `make` command will also print basic auth credentials upon completion 
that can be used to sign in to the OpenFaas management console.
The OpenFaas management console can be accessed at https://gateway.example.

## Exploring

These are some ways to get started exploring the deployed example project.

### OCI web console

The OCI web console can be reached at https://console.us-phoenix-1.oraclecloud.com.
`us-phoenix-1` can be replaced with your home region if different.

2 places to start with:

- https://console.us-phoenix-1.oraclecloud.com/networking/vcns
- https://console.us-phoenix-1.oraclecloud.com/containers/clusters 

Be sure to pick the `cloud-native` compartment under `List Scope` in the sidebar.
Resources created by this example project are in the `cloud-native` compartment.

### OpenFaas management console

The OpenFaas console is available at https://gateway.example.
Use the basic auth credentials provided at the end of `make` to sign in.

From here, you can view and invoke any deployed functions.
You can also deploy any new functions from publicly available OpenFaas registry or custom Docker images.

### command line

To explore the environment and Kubernetes cluster from the command line, run `make shell`.

This will run a Docker container with an interactive bash session.
The container comes installed with the tools you would need to interact with any component.

- [oci](https://docs.cloud.oracle.com/en-us/iaas/Content/GSG/Tasks/gettingstartedwiththeCLI.htm) is the cli for Oracle Cloud.
You will be prompted to login with OCI on start of the container. 
- [kubectl](https://kubernetes.io/docs/reference/kubectl/overview/) will be available, with context already configured to the OKE cluster.
- [helm](https://helm.sh/docs/) for interacting with deployed charts.
- [faas-cli](https://github.com/openfaas/faas-cli) is the cli for OpenFaas.
This can be used to deploy new functions, among other things.
It will already be logged in to the deployed OpenFaas gateway.
- [artillery](https://artillery.io/docs/cli-reference/) is available for load testing the app function.
- [tmux](https://github.com/tmux/tmux/wiki) is available to run multiple things at once within single container.
This is avoid bound port conflicts running multiple instances of `make shell`. 

Some things you could do:

- View all namespaces in the Kubernetes cluster, as an overview of what is deployed.
`kubectl get ns`
- Port forward [Grafana](https://grafana.com/docs/grafana/latest/) to view OpenFaas metrics.
`kubectl -n grafana port-forward svc/grafana --address 0.0.0.0 3000:80`
Grafana will be reachable on host at http://localhost:3000, with `admin:password` for credentials.
A dashboard is pre-installed to view basic metrics of deployed functions.
- Load test the deployed function.
`artillery run artillery.yaml`
[artillery.yaml](artillery.yaml) can be edited on host and re-ran.
- Inspect the deployed app function.
`faas-cli describe app -g https://gateway.example`

## Clean Up

When you are finished with the deployed application and infrastructure,
there is a provided command to tear everything down.

`make destroy`

This command can also take 10+ minutes to successfully complete.

You will be prompted at the beginning of the script to sign in to OCI,
just as you were when standing everything up.

This command will remove everything deployed to the Kubernetes cluster,
then proceed to destroy all resources in OCI, up to and including the OCI compartment.
