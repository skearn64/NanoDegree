# Azure Infrastructure Operations Project: Deploying a scalable IaaS web server in Azure

### Introduction
For this project, the requirement is to create and deploy a scalable cluster of web servers that form part of an address pool, associated with a load balancer. The load balancer is accessed through a public facing IP.
A Linux Ubuntu 18.04 image is to be built using Packer, with the image being called from within a Terraform template.
The Terraform template will contain calls to Azure resources to create the required elements, including a resource group, availability set, load balancer and backend address pool for the VM's created, a public IP, subnet, network interfaces, associated network security groups and the virtual machines themselves.
All the resources will however only be created if they have the relevant tags associated due to a policy created and assigned that check for the inclusion of tags.
The Terraform variables file (vars.tf) contains the ability to scale the number of VM's to be created. This is explained further within this ReadMe file.

### Getting Started
1. Clone this repository or extract the files from the zip file skproject1.zip

2. Confirm that you have the Azure CLI installed, Packer downloaded and configured, and Terraform installed

3. Open the command line interface. Use command prompt in Windows or Terminal for MAC and change to the project directory if running from your machines hard disk.

4. Check that the following files are available (required if creating the web server deployment from scratch);
project1policy.json - Policy definition to ensure tags are present
server.json - Packer Image file creating a Ubuntu 18.04 Linux VM
main.tf - main terraform template with the resources required to deploy the web server
vars.tf - the variables declared within the terraform template

Note: The deployment of this web server has a default region of UK South and therefore the attribute platform_fault_domain_count stated in the resource azurerm_availability_set has been explicitly set to 2 in the terraform file main.tf to override the default value of 3. Not setting this would cause an error when building.

When running the packer build command the following attributes will need to be set as export variables as these are set-up during the creation of the packer image;
Client_ID, Client_Secret, Subscription_Id and Tenant_Id
These can be obtained from your account and by creating a Contributor role for your specific subscription.

### Dependencies
1. Create an [Azure Account](https://portal.azure.com)
2. Install the [Azure command line interface](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest)
3. Install [Packer](https://www.packer.io/downloads)
4. Install [Terraform](https://www.terraform.io/downloads.html)

### Instructions
Once all the files are present then the following commands should be run to create the packer image and to deploy the VM's using terraform.
Pre-Reqs: Ensure all variables required to create the packer image have been exported

1. On the command line type the following to create the packer image;
packer build server.json

2. Once the packer image has been successfully created now check the deployment via Terraform
terraform plan -out solution.out
This will ask for a password, the prefix to use and the username to create
This will return with the list of resources that will be created. 20 in total

3. Now deploy the web server using one of the following command;
terraform apply (this will again ask for the password, prefix and username)

or

terraform apply solution.out (this will take the values supplied when terraform plan was run)

This will take some time to complete, but once finished it will display that the apply has completed with 16 items added.

Creation of the VM's, Virtual network, NIC's, subnet and managed disks can be checked in the Azure Portal.

4. To destroy/remove the web server deployment tun the command;
terraform destroy

This will again ask for the password, prefix and username previously supplied.
This will list the items to be destroyed and a count of 16.
Confirmation of the destroy action will be required. Typing 'yes' will carry out the destroy action.

Customizing the deployment through the vars.tf is possible for the following two variables

  location - the region where the deployment will be created. Default is UK South
  counter - the number of VM's to create for the deployment. Default is 2

These are currently not required when terraform plan or terraform apply is run as the default values are taken. To change the location or the number of VM's to be created remove the default attributes and save the file.

This will ask for the location and the number of VM's to be created in addition to the other 3 arguments.

### Output
Running the terraform plan command will display the number of items that will be added. For the deployment of the web server 2 VM's will be created (2 is the default value used in the vars.tf file).
The Terraform plan will report that 20 items will be added

Running the terraform apply command will create the 20 items, displaying the message;
Apply complete! Resources: 20 added, 0 changed, 0 destroyed

Terraform show will display the items created/added

Running the command Terraform destroy will produced the final message one complete.
Destroy complete! Resources: 20 destroyed.
