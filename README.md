# cloud-native

Example cloud native solution, using serverless functions on Kubernetes in a public cloud provider.
Includes a command to deploy everything in your own cloud account in an automated fashion. 

### Application

The application in this cloud native example is an OpenFaas function, using [Node.js](https://nodejs.org/).

[OpenFaas](https://www.openfaas.com/) is a platform for serverless functions,
 that can be run on top of Kubernetes.
Functions are packaged, run, and managed as [Docker](https://www.docker.com/) containers.

### Platform

[Kubernetes](https://kubernetes.io/) is the platform used in this example, specifically [OKE](https://docs.cloud.oracle.com/en-us/iaas/Content/ContEng/Concepts/contengoverview.htm). 
OKE is a managed Kubernetes service in OCI.

[Ingress Nginx](https://kubernetes.github.io/ingress-nginx/) is deployed for the publicly accessible ingress to the OpenFaas service,
with [Cert Manager](https://cert-manager.io/) handling the self-signed TLS certificate.
 
[Helm](https://helm.sh/) and [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/) are the main tools used to deploy everything to the Kubernetes cluster.

### Infrastructure

[Oracle Cloud](https://www.oracle.com/cloud/) is a public cloud provider from Oracle, referred to as OCI.
This example uses OCI for all infrastructure, such as networking and OKE,
utilizing the publicly available free trial.

[Terraform](https://www.terraform.io/) is used to define and create all infrastructure, services, and resources used in OCI. 

## Prerequisites

There are a few items that must be configured before deploying this project.
If you do not meet these prerequisites, you will not be able to successfully deploy the project.

### Oracle Cloud account

You must active a free trial account for Oracle Cloud, or otherwise have an existing paid account.
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

Read [this](https://docs.cloud.oracle.com/en-us/iaas/Content/General/Concepts/identifiers.htm) if you need help finding this information.

### Docker

Docker must be installed on the host machine.
The majority of scripts and tooling, including the main creation command, are run through a Docker container locally.
Port `8181` must not be in use, as this is used for automated login to OCI.

### Browser

A modern browser must be available on the host machine.
Most commands in this project will fetch a security token for OCI access.
This is done through a browser-based login flow. 

## Creation

The cloud infrastructure, Kubernetes setup, and application are deployed by a single command.
This process will likely take 10+ minutes to finish.
If at any point it seems like something may be stuck, do not interrupt or cancel the process.
It is likely waiting on a particular cloud resource to finish provisioning before moving on.

### Steps
1. Make sure prerequisites are in place, defined in the previous section.
1. Clone this repository.
1. Run `make`.

It will prompt you early on to sign in to OCI with a given URL.
Open that URL in your browser and sign in with your OCI account credentials.
When you see:
 
> Authorization completed! Please close this window and return to your terminal to finish the bootstrap process.

return to the command line.
 
When `make` has finished, it will print instructions for a line to be added to your local hosts.
Read [this](https://support.rackspace.com/how-to/modify-your-hosts-file/) if you are unfamiliar with how to do this. 
 
Once you have followed the above steps, the application can be accessed at https://gateway.example/function/app.
This demonstration uses a self-signed certificate, so you will see an insecure warning message from your browser.
This is expected; allow a security exception to continue.


The `make` command will also print basic auth credentials upon completion 
that can be used to sign in to the OpenFaas management gateway.
The OpenFaas management console can be accessed at https://gateway.example.

## Optional Dependencies

These are optional dependencies that are not required to stand-up or tear-down the project.
However, these may be useful if you would like to interact with various components to learn more.

These tools are available by running the same Docker container used during creation,
if you wish to use them without installing on your host:

`make shell`

Once the bash session has started, run `./scripts/login.sh`.
This will prompt you to sign in to OCI, and will handle the kubeconfig for `kubectl`.

[oci](https://docs.cloud.oracle.com/en-us/iaas/Content/GSG/Tasks/gettingstartedwiththeCLI.htm) is the cli for Oracle Cloud. 

`helm` and `kubectl` are for interacting with the OKE cluster and any deployed resources.
Follow these [directions](https://docs.cloud.oracle.com/en-us/iaas/Content/ContEng/Tasks/contengdownloadkubeconfigfile.htm) for authenticating with OKE.
 
[faas-cli](https://github.com/openfaas/faas-cli) is the cli for OpenFaas.
This can be used to deploy new functions, among other things.
You must login with the OpenFaas gateway, `https://gateway.example`,
with the credentials printed at the end of the main creation script.

## Clean Up

When you are finished with the deployed application and infrastructure,
there is a provided command to tear everything down.

`make destroy`

This command can also take 10+ minutes to successfully complete.

You will be prompted at the beginning of the script to sign in to OCI,
just as you were when standing everything up.

This command will remove everything deployed to the Kubernetes cluster,
then proceed to destroy all resources in OCI, up to and including the OCI compartment.
