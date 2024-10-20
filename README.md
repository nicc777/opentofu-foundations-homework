
Homework from https://github.com/massdriver-cloud/opentofu-foundations

- [Week 4](#week-4)
  - [Preparations](#preparations)
  - [Observations / Learnings](#observations--learnings)
    - [Challenge 1 - SSH into an Instance](#challenge-1---ssh-into-an-instance)
    - [Challenge 2: Use an Autoscaling Group](#challenge-2-use-an-autoscaling-group)
    - [Challenge 3: Change Security Group Rules](#challenge-3-change-security-group-rules)
    - [Challenge 4: Improve Database Security](#challenge-4-improve-database-security)
    - [Challenge 5: Create a Load Balancer](#challenge-5-create-a-load-balancer)
- [Week 3](#week-3)
  - [Preparations](#preparations-1)
  - [Observations / Learnings](#observations--learnings-1)
    - [Challenge Outputs](#challenge-outputs)
      - [Challenge 1: Tag your ec2 instances with a random cat fact](#challenge-1-tag-your-ec2-instances-with-a-random-cat-fact)
      - [Challenge 2: Add the conversion rate for the Mexican Peso](#challenge-2-add-the-conversion-rate-for-the-mexican-peso)
      - [Challenge 3: Use a ternary expression to sort a user provided list and enable user configuration of the sort order](#challenge-3-use-a-ternary-expression-to-sort-a-user-provided-list-and-enable-user-configuration-of-the-sort-order)
- [Week 2](#week-2)
  - [Preparations](#preparations-2)
  - [Observations / Learnings](#observations--learnings-2)
    - [Testing for a new version of a module](#testing-for-a-new-version-of-a-module)
- [Week 1](#week-1)
  - [Preparations](#preparations-3)
  - [Various other Changes or Improvements](#various-other-changes-or-improvements)
  - [Observations / Learnings](#observations--learnings-3)
    - [Getting the EC2 instance DNS name](#getting-the-ec2-instance-dns-name)
    - [DB Access](#db-access)


# Week 4

Challenge Progress

| Challenge                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      | Progress    |
|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|-------------|
| **SSH into an Instance**: Use the SSH key to access one of the web instances.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  | Done        |
| **Use an Autoscaling Group**: Instead of managing the EC2 instances with a `count` convert it to an [AWS Autoscaling Group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_group).                                                                                                                                                                                                                                                                                                                                                                                                    | Done        |
| **Change Security Group Rules**: Update your security group rules to use the recommended [`aws_vpc_security_group_ingress_rule`](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_ingress_rule) and [`aws_vpc_security_group_gress_rule`](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_egress_rule).                                                                                                                                                                                                                           | Done        |
| **Improve Database Security**: Instead of giving database access to the entire VPC, only give access to the security group of the EC2 instance. Even better, add a conditional to the database module that, only if enabled, will grant access to the entire VPC.                                                                                                                                                                                                                                                                                                                                                              | Done        |
| **Create a Load Balancer**: Place a load balancer in front of the EC2 instance autoscaling group. NOTE: elastic load balancers do not have a free tier. This will incur costs in your AWS account.                                                                                                                                                                                                                                                                                                                                                                                                                             | Done        |

## Preparations

Basic start:

```shell
# Assuming the repo is checked out and the current working directory is the root of the project

# First, set the alias to tofu to where ever the binary is
alias t=...

# Init
cd week-4/code
t init -upgrade

# Set our AWS profile for calling AWS API's
export AWS_PROFILE=...

# Run this regularly to keep things look nice
t fmt -recursive
```

## Observations / Learnings

```shell
# Basic plan/apply sequence:

t apply "my_plan" -auto-approve

t apply "my_plan"
```

### Challenge 1 - SSH into an Instance

* The default SSH setting was set to `true` in the EC2 instance module. For better control, I added my own variables in the root directory and added a `variables.tf` file where the default value is set to `false`. In the root `main.tf` file I then added the `enable_ssh` parameter to pass my preferred value to the module.
* I realized also that I need the SSH private key in order to SSH into the instance. Best practice is to mask sensitive material, so whenever I run the modified code with the sensitive data I would get the following:

```shell
t apply "my_plan"                                
module.aws_instance.aws_instance.this[0]: Modifying... [id=i-0e33f522ae0ff812c]
module.aws_instance.aws_instance.this[0]: Modifications complete after 4s [id=i-0e33f522ae0ff812c]

Apply complete! Resources: 0 added, 1 changed, 0 destroyed.

Outputs:

db_endpoint = "week4-db.cmxwptyc08tr.us-west-2.rds.amazonaws.com:3306"
instance_public_ip = [
  [
    "52.36.77.40",
  ],
]
private_key = <sensitive>
```

* I resolved the SSH private key issue by adding a variable for my home directory and writing the private key to a file:

```shell
export TF_VAR_home_directory=$HOME

```

* Before running `t plan` again, I had to run `t init -upgrade` again as I needed to use additional providers. I then recreated the stack from scratch.
  * In retrospect, I should have first checked if I could just apply the changes, as the `destroy` also deleted the DB instance. When I have time I will try to revisit this part to try add add the SSH private key to the EC2 insatnce without the complete re-deployment

```shell
# Final plan, with SSH enabled and expecting the SSH key to be written to a local file
t plan -var-file=my_variables.tfvars -out=my_plan 

t apply "my_plan"

# Test SSH access
ssh -i ~/.ssh/opentofu_foundations_temporary_key.pem ec2-user@52.35.154.160 whoami
ec2-user

```

### Challenge 2: Use an Autoscaling Group

Most of this work was already done in week 1, so I reused a lot of what I learned there.

```shell
t init -upgrade

t plan -var-file=my_variables.tfvars -out=my_plan

t apply "my_plan"

# Get the host DNS value
sh ./get_instance_dns.sh
ec2-54-187-39-247.us-west-2.compute.amazonaws.com

# Test SSH still works:
ssh -i ~/.ssh/opentofu_foundations_temporary_key.pem ec2-user@ec2-54-187-39-247.us-west-2.compute.amazonaws.com whoami
ec2-user
```

### Challenge 3: Change Security Group Rules

* Basically copied what was learned from week 1
* I had to figure out how to add a conditional to a `for_each` loop

### Challenge 4: Improve Database Security

* I could not find a way to modify the security groups without re-creating the DB.
  * In real life, I believe I would follow the following process:
    * Bring apps down for "maintenance"
    * Take a DB snapshot.
    * Create a new DB with the new security groups, and use the earlier DB snapshot
    * Re-enable the apps
    * TEST
    * Destroy the old DB instance
 

### Challenge 5: Create a Load Balancer

Simply added the Application load balancer configuration and tested:

```shell
curl -vvv http://my-alb-395924136.us-west-2.elb.amazonaws.com
*   Trying 54.149.32.22:80...
* Connected to my-alb-395924136.us-west-2.elb.amazonaws.com (54.149.32.22) port 80 (#0)
> GET / HTTP/1.1
> Host: my-alb-395924136.us-west-2.elb.amazonaws.com
> User-Agent: curl/7.81.0
> Accept: */*
> 
* Mark bundle as not supporting multiuse
< HTTP/1.1 302 Found
< Date: Sun, 20 Oct 2024 14:13:06 GMT
< Content-Type: text/html; charset=UTF-8
< Content-Length: 0
< Connection: keep-alive
< Server: Apache/2.4.62 (Debian)
< X-Powered-By: PHP/8.2.24
< Expires: Wed, 11 Jan 1984 05:00:00 GMT
< Cache-Control: no-cache, must-revalidate, max-age=0
< X-Redirect-By: WordPress
< Location: http://my-alb-395924136.us-west-2.elb.amazonaws.com/wp-admin/install.php
< 
* Connection #0 to host my-alb-395924136.us-west-2.elb.amazonaws.com left intact
```

# Week 3

Challenge Progress

| Challenge                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      | Progress      |
|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|---------------|
| **Tag your ec2 instances with a random [cat fact](https://catfact.ninja/)**: Using the ExchangeRate function as a guide, retrieve a cat fact and add it as a tag to your ec2 instance module.                                                                                                                                                                                                                                                                                                                                                                                                                                  | Done          |
| **Add the conversion rate for the Mexican Peso**: Using the [api documentation](https://fiscaldata.treasury.gov/datasets/treasury-reporting-rates-exchange/treasury-reporting-rates-of-exchange), add the conversion rate for the Peso to your environment variables.                                                                                                                                                                                                                                                                                                                                                          | Done          |
| **Use a ternary expression to sort a user provided list and enable user configuration of the sort order**: Use the [sort](https://developer.hashicorp.com/terraform/language/functions/sort) and [reverse](https://developer.hashicorp.com/terraform/language/functions/reverse) functions in a ternary to sort a list by ascending or descending order based on a user input variable.                                                                                                                                                                                                                                        | Done          |

## Preparations

Basic start:

```shell
# Assuming the repo is checked out and the current working directory is the root of the project

# First, set the alias to tofu to where ever the binary is
alias t=...

# Init
cd week-3/code/functions
t init
```

## Observations / Learnings

* For challenge one I basically did copy and paste of the Exchange Rate code and just made minor adjustments to add cat facts functionality. No major issues, even though I have never coded in Go. I guess sometimes it's ok to just get lucky.
* For the second challenge I decided to try and add a variable so that I can switch more easily between currencies. 
* I was already partly familiar with the various functions based on earlier exercises, so challenge 3 was really straight forward. However, reading through all the available functions, I feel I am still missing out on a lot of potential, but I am sure the future challenges will remedy that!

Using variables, from challenge 2 onward:

```shell
t plan -var-file=my_variables.tfvars

t apply -var-file=my_variables.tfvars -auto-approve
```

### Challenge Outputs

#### Challenge 1: Tag your ec2 instances with a random cat fact

Execution:

```shell
t apply -auto-approve
```

Output:

```text
data = <<EOT
#!/bin/bash
yum update -y
amazon-linux-extras install docker -y
service docker start
usermod -a -G docker ec2-user
docker run -d \
  -e WORDPRESS_DB_HOST=xxxxxxxxxxx \
  -e WORDPRESS_DB_USER=xxxxxxxxxxxx \
  -e WORDPRESS_DB_PASSWORD=xxxxxxxxxxxxxxx \
  -e CAD_EXCHANGE_RATE=1.352 \
  -e CAT_FACT=Milk can give some cats diarrhea. \
  -p 80:80 xxxxxxxxxxxx:xxxxxxxxxxxx
EOT
```

#### Challenge 2: Add the conversion rate for the Mexican Peso

Execution:

```shell
t apply -var-file=my_variables.tfvars -auto-approve
```

Output:

```text
data = <<EOT
#!/bin/bash
yum update -y
amazon-linux-extras install docker -y
service docker start
usermod -a -G docker ec2-user
docker run -d \
  -e WORDPRESS_DB_HOST=xxxxxxxxxxx \
  -e WORDPRESS_DB_USER=xxxxxxxxxxxx \
  -e WORDPRESS_DB_PASSWORD=xxxxxxxxxxxxxxx \
  -e EXCHANGE_RATE=19.655 \
  -e EXCHANGE_RATE_CURRENCY=Mexico-Peso \
  -e CAT_FACT=Approximately 40,000 people are bitten by cats in the U.S. annually. \
  -p 80:80 xxxxxxxxxxxx:xxxxxxxxxxxx
EOT
```

#### Challenge 3: Use a ternary expression to sort a user provided list and enable user configuration of the sort order

First, update the local variables file (`my_variables.tfvars` in my case), with some initial values, for example:

```text
currency_selection = "Mexico-Peso"
user_input = ["d", "e", "c", "a", "b"]
user_input_sort_ascending = true
```

Execution, with the `user_input_sort_ascending` set to `true`:

```shell
t apply -var-file=my_variables.tfvars -auto-approve
```

Output:

```text
data = <<EOT
#!/bin/bash
yum update -y
amazon-linux-extras install docker -y
service docker start
usermod -a -G docker ec2-user
docker run -d \
  -e WORDPRESS_DB_HOST=xxxxxxxxxxx \
  -e WORDPRESS_DB_USER=xxxxxxxxxxxx \
  -e WORDPRESS_DB_PASSWORD=xxxxxxxxxxxxxxx \
  -e USER_INPUT=a,b,c,d,e \
  -e EXCHANGE_RATE=19.655 \
  -e EXCHANGE_RATE_CURRENCY=Mexico-Peso \
  -e CAT_FACT=Long, muscular hind legs enable snow leopards to leap seven times their own body length in a single bound. \
  -p 80:80 xxxxxxxxxxxx:xxxxxxxxxxxx
EOT
```

Then, do another run with the `user_input_sort_ascending` set to `false`:

Output:

```text
data = <<EOT
#!/bin/bash
yum update -y
amazon-linux-extras install docker -y
service docker start
usermod -a -G docker ec2-user
docker run -d \
  -e WORDPRESS_DB_HOST=xxxxxxxxxxx \
  -e WORDPRESS_DB_USER=xxxxxxxxxxxx \
  -e WORDPRESS_DB_PASSWORD=xxxxxxxxxxxxxxx \
  -e USER_INPUT=e,d,c,b,a \
  -e EXCHANGE_RATE=19.655 \
  -e EXCHANGE_RATE_CURRENCY=Mexico-Peso \
  -e CAT_FACT=The cat's tail is used to maintain balance. \
  -p 80:80 xxxxxxxxxxxx:xxxxxxxxxxxx
EOT
```

# Week 2

Challenge Progress

| Challenge                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      | Progress      |
|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|---------------|
| **Enhance the Database Module**: Add [variables](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_instance) to configure more database options, such as backup retention, multi-AZ deployments, or storage type. Add [validations](https://opentofu.org/docs/language/expressions/custom-conditions/) to some of the variables for the database `variables.tf` (`instance_class`, `allocated_storage`, `engine`, `engine_version`). Set `password` in `aws_db_instance/variables.tf` to [sensitive](https://opentofu.org/docs/v1.7/language/values/variables/#suppressing-values-in-cli-output). | Done          |
| **Parameterize Security Groups**: Modify the security group definitions for `aws_instance` and `aws_db_instance` to accept lists of ports and protocols as variables.                                                                                                                                                                                                                                                                                                                                                                                                                                                          | Done          |
| **Use AWS Secrets Manager**: Store the database password in [AWS Secrets Manager](https://docs.aws.amazon.com/secretsmanager/latest/userguide/intro.html) (or [SSM](https://docs.aws.amazon.com/systems-manager/latest/userguide/systems-manager-parameter-store.html)) and retrieve it in your configuration.                                                                                                                                                                                                                                                                                                                 | Done          |
| **Create a VPC Module**: Create a module for VPC components like subnets, route tables, and internet gateways.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 | Done          |
| **Implement Module Versioning**: [Tag your modules](https://opentofu.org/docs/language/modules/sources/) with versions and test upgrading between versions                                                                                                                                                                                                                                                                                                                                                                                                                                                                     | Done          |

## Preparations

I started with the same state as for week 1 and ensured that week 1 preparations were done (or at least still valid).

## Observations / Learnings

* I started by first going through the [OpenTofu Modules documentation](https://opentofu.org/docs/language/modules/)
  * For the challenges I reviewed the [GitHub module referencing](https://opentofu.org/docs/language/modules/sources/#github) in order to understand how versioning can be accomplished. I noticed that other sources, like using the `Module Registry` can take a `version` parameter. I then went through the [Module Registry documentation](https://opentofu.org/docs/internals/module-registry-protocol/) to further understand how versioning actually works.
* Referred to [this resource](https://www.perrotta.dev/2024/05/terraform-aws-deployment-to-random-availability-zones/) for learning about how I can get the availability zones and then select a random one ofr the DB deployment
* Created a separate module for security group creation, and added support to handle a variable list of ports to allow ingress. Adding protocols as part of the list did not make sense in this context, so I left it out.
  * I learned that when using `for_each`, only string types are permitted, so I had to add the port numbers as strings and then use another `tonumber()` function to convert it to an actual number.
* I choose to use secrets manager and also created a separate module for that. For some reason I have to run the `plan` / `apply` cycle twice as the secret version is not available on the first round. Not 100% sure why this is the case.
* For the VPC I used a public module called [terraform-aws-modules/terraform-aws-vpc](https://library.tf/modules/terraform-aws-modules/vpc/aws/latest)
* Because I created a custom VPC with only public subnets, I had to add a `publicly_accessible` argument to the RDS resource. For the exercise I did this as we might want to connect directly to the DB. Typically the DB will always be in a private subnet.
* When not using the default VPC, more resources need to be adapted to target the VPC. I had to deal with a lot of errors about something not belonging to the same VPC as many resources by default target the default VPC.
* For the versioning, I updated the modules to target a GitHub URL, following instructions from [the OpenTofu documentation](https://opentofu.org/docs/language/modules/sources/#github). I opted to try TAG references as [documented here](https://opentofu.org/docs/language/modules/sources/#generic-git-repository).
  * The actual exercise will be done on separate tags on the main branch and not in the exercise branch or by using some other commit hash.
  * I had to run `tofu init -upgrade` after changes
  * It appeared that the DB failed to create every time from a fresh `apply` but this was resolved after I added `depends_on` in the DB module. As I understand OpenTofu, this should not strictly speaking be required (it worked sometimes without it), but somehow this appears to make it deploy successfully every time. Not sure if this is an issue or if I miss something. 
* I did not put too much thought into a Git workflow and I ended up paying the price. I recovered mostly, but I once again learned to rather plan from the start. Frustrating :-D

### Testing for a new version of a module

I assume that one of the key operational tasks would be to update your stack if a significant enough change present itself in a upstream module.

For this reason I attempted to test this scenario by creating a new release and then pointing to an updated module (new version) going through the whole `init`, `plan` and `apply` cycles.

I realized quickly the ideal scenario is to have each module in each own Git repo, because the mixed version by tag use does not look nice, neither does it look manageable.

I further decided to make a updated version of the instance template by just adding a tag and decided to tag this release as `2.0.1`. However, I will keep the `main` branch pointed to the original `2.0.0` release branch and only experiment locally in a working branch pointing to `2.0.1` for the launch template changes.

My working branch is named `week2-test-new-version-branch` and I will hopefully remember to not delete it... 

Changes:

```text
OpenTofu will perform the following actions:

  # module.aws_instance.aws_instance.this will be updated in-place
  ~ resource "aws_instance" "this" {
        id                                   = "i-0c6194fc2dccd8b70"
      ~ tags                                 = {
          - "Name"  = "week-2-instance" -> null
          - "Owner" = "Nico" -> null
        }
      ~ tags_all                             = {
          - "Name"        = "week-2-instance" -> null
          - "Owner"       = "Nico" -> null
            # (2 unchanged elements hidden)
        }
      ~ user_data                            = "dada918475ba3288ff91f95f07f7832a5bb19293" -> "7ee573b756c8eab62f11490b8f408b9b0aff03b2"
        # (30 unchanged attributes hidden)

        # (9 unchanged blocks hidden)
    }

  # module.aws_instance.aws_launch_template.this will be updated in-place
  ~ resource "aws_launch_template" "this" {
        id                      = "lt-027262146d7881817"
      ~ latest_version          = 1 -> (known after apply)
        name                    = "week-2-instance-lt20241006090422872800000004"
        tags                    = {}
        # (11 unchanged attributes hidden)

      ~ tag_specifications {
          ~ tags          = {
                "Name"  = "week-2-instance"
              + "Note"  = "Some note..."
                "Owner" = "Nico"
            }
            # (1 unchanged attribute hidden)
        }

        # (1 unchanged block hidden)
    }

Plan: 0 to add, 2 to change, 0 to destroy.

```

The actual end result with just a new template version. Nothing changed on the running instance, which is kind of expected sine I have not launch the instance via an Auto Scaling Group. However, the change was good enough for me to test the concept.

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

