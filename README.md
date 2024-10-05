
Homework from https://github.com/massdriver-cloud/opentofu-foundations

- [Week 2](#week-2)
  - [Preparations](#preparations)
  - [Observations / Learnings](#observations--learnings)
- [Week 1](#week-1)
  - [Preparations](#preparations-1)
  - [Various other Changes or Improvements](#various-other-changes-or-improvements)
  - [Observations / Learnings](#observations--learnings-1)
    - [Getting the EC2 instance DNS name](#getting-the-ec2-instance-dns-name)
    - [DB Access](#db-access)


# Week 2

Challenge Progress

| Challenge                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      | Progress      |
|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|---------------|
| **Enhance the Database Module**: Add [variables](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_instance) to configure more database options, such as backup retention, multi-AZ deployments, or storage type. Add [validations](https://opentofu.org/docs/language/expressions/custom-conditions/) to some of the variables for the database `variables.tf` (`instance_class`, `allocated_storage`, `engine`, `engine_version`). Set `password` in `aws_db_instance/variables.tf` to [sensitive](https://opentofu.org/docs/v1.7/language/values/variables/#suppressing-values-in-cli-output). | Done / Merged |
| **Parameterize Security Groups**: Modify the security group definitions for `aws_instance` and `aws_db_instance` to accept lists of ports and protocols as variables.                                                                                                                                                                                                                                                                                                                                                                                                                                                          | In Progress   |
| **Use AWS Secrets Manager**: Store the database password in [AWS Secrets Manager](https://docs.aws.amazon.com/secretsmanager/latest/userguide/intro.html) (or [SSM](https://docs.aws.amazon.com/systems-manager/latest/userguide/systems-manager-parameter-store.html)) and retrieve it in your configuration.                                                                                                                                                                                                                                                                                                                 | Not Started   |
| **Create a VPC Module**: Create a module for VPC components like subnets, route tables, and internet gateways.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 | Not Started   |
| **Implement Module Versioning**: [Tag your modules](https://opentofu.org/docs/language/modules/sources/) with versions and test upgrading between versions                                                                                                                                                                                                                                                                                                                                                                                                                                                                     | Not Started   |

## Preparations

I started with the same state as for week 1 and ensured that week 1 preparations were done (or at least still valid).

## Observations / Learnings

* I started by first going through the [OpenTofu Modules documentation](https://opentofu.org/docs/language/modules/)
  * For the challenges I reviewed the [GitHub module referencing](https://opentofu.org/docs/language/modules/sources/#github) in order to understand how versioning can be accomplished. I noticed that other sources, like using the `Module Registry` can take a `version` parameter. I then went through the [Module Registry documentation](https://opentofu.org/docs/internals/module-registry-protocol/) to further understand how versioning actually works.
* Referred to [this resource](https://www.perrotta.dev/2024/05/terraform-aws-deployment-to-random-availability-zones/) for learning about how I can get the availability zones and then select a random one ofr the DB deployment
* Created a separate module for security group creation, and added support to handle a variable list of ports to allow ingress. Adding protocols as part of the list did not make sense in this context, so I left it out.
  * I learned that when using `for_each`, only string types are permitted, so I had to add the port numbers as strings and then use another `tonumber()` funtion to convert it to an actual number.

# Week 1

## Preparations

* In AWS EC2 console, create a SSH key pair for SSH access to the wordpress server. An alternative could be to use the [key_pair](https://library.tf/providers/hashicorp/aws/latest/docs/resources/key_pair) resource to create a key pair, but that would also require some local script to generate the secret key and export the public key material for use in as a variable input.
* ~~In the default VPC, tag at least one public `subnet` with a tag named `experimental` and a value of `1`.~~ - This solution assumes a default VPC with Public only subnets.

## Various other Changes or Improvements

* Added AWS SecretsManager to store DB password
* Used AWS SecretsManager secret value in the creation of EC2 and RDS resources
* Added a variable for the HTTP ingress in order to limit it to only my public IP address
* Added selection of AWS EC2 AMI and removed hard coded AMI

## Observations / Learnings

* Used https://library.tf/ for documentation on the AWS provider. Useful links:
  * [SecretsManager Resource](https://library.tf/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret)
  * [SecurityGroup Resource](https://library.tf/providers/hashicorp/aws/latest/docs/resources/security_group)
  * [EC2 Instance Resource](https://library.tf/providers/hashicorp/aws/latest/docs/resources/instance)
  * [EC2 Launch Template](https://library.tf/providers/hashicorp/aws/latest/docs/resources/launch_template)
  * [AutoScaling Group](https://library.tf/providers/hashicorp/aws/latest/docs/resources/autoscaling_group)
  * [random_pet](https://library.tf/providers/ContentSquare/random/latest/docs/resources/pet)
* Discoverd once again that limits are not always what you would think, for example MariaDB RDS maximum password length is 41 characters.
* AWS CloudTrail was instrumental in tracking down sources of failures. Initially I had a very basic resource definition for the secret and when the resources was re-created after some changes, it failed because the resource was still being deleted on AWS side. I updated `aws_secretsmanager_secret` with additional arguments to make replacing easier and more instant.
* The current solution does not cater for Password Rotation, as there is no easy way to do this with the current set-up. I would like to solve this at some later point, but for now I will just first see how the course proceeds - perhaps there is something about this later.
* Using the [`count` Meta-Argument](https://opentofu.org/docs/language/meta-arguments/count/), I can create the DB public access based on a boolean value, regardless of the trusted public IP address I provided. This is really cool for deciding to create a resource or not - in this case choosing to create the security group to allow access from the trusted CIDR.
* It feels like the subnet selection could be better, but I have not really found the solution I'm more happy with yet. Ideally, the VPC will also be crated by OpenTofu, which will make automatic subnet selection a lot easier.
  * _*UPDATE*_: Following [this post](https://daringway.com/how-to-select-one-random-aws-subnet-in-terraform/) I was able to adapt the example to now select a random subnet. However, the `aws_subnet_ids` section is deprecated and replaced with [`aws_subnets`](https://library.tf/providers/hashicorp/aws/latest/docs/data-sources/subnets)
* In the current configuration, anytime something changes that requires the plan to be updated, the DB credentials change. ~~I have not figured out exactly what the root cause of this behavior is~~.
  * It seems this is by design and there is [an open issue of GitHub](https://github.com/hashicorp/terraform-provider-aws/issues/28733).
  * I had to add a trigger argument to the Auto Scaling group in order to force an instance refresh whenever the DB credentials are updated. The current implementation is not ideal in my opinion, as users may experience downtime during the initial instance refresh until all instances can have the updated credentials. It is still better that my initial configuration.
* I decided to populate some variables at runtime using environment variables. Here are my reasons:
  * Variable `trusted_cidrs_for_wordpress_access` - my public IP address could change, but it should remain stable at least for a day, so I guess using a small shell one-liner to create an environment variable is the easiest solution here that avoids manually visiting a website every time and manually updating a file.
  * Variable `ssh_keypair_name` is an environment variable simply because I want to disclose as little as possible information around anything related to private keys.
  * Variable `enable_public_mariadb_access` could be considered very dynamic and could change between update cycles.

Basic shell history:

```shell
# Assuming the repo is checked out and the current working directory is the root of the project

# First, set the alias to tofu to where ever the binary is
alias t=...

# Init
cd week-1/code
t init

# Setup some environment variables
export AWS_PROFILE=...
export TF_VAR_trusted_cidrs_for_wordpress_access="`dig +short txt ch whoami.cloudflare @1.0.0.1 | tr -d '\"' | awk '{print $1\"/32\"}'`"
export TF_VAR_ssh_keypair_name="...."

# Optionally, if you want to access the DB from your local machine
export TF_VAR_enable_public_mariadb_access=true

# Apply
t plan -var-file=my_variables.tfvars -out=my_plan
t apply "my_plan"
```

Current contents of `my_variables.tfvars`:

```text
name_prefix = "test1"
image = {
    name = "wordpress"
    tag = "latest"
}
```

### Getting the EC2 instance DNS name

```shell
sh ./get_instance_dns.sh
```

> [!NOTE]  
> OpenTofu does not directly create the instances, and it is therefore better to use the AWS CLI to get the public DNS entry for the instance

### DB Access

Get the hostname and DB username from the OpenTofu output and the password from secrets manager and connect:

```shell
export DB_HOST=....
export DB_USERNAME=...
podman run -it --rm mariadb mariadb --host $DB_HOST --user $DB_USERNAME --password --database wordpress
```

