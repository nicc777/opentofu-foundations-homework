# opentofu-foundations-homework

Homework from https://github.com/massdriver-cloud/opentofu-foundations

# Progress

## Week 1

Changes:

* Added AWS SecretsManager to store DB password
* Used AWS SecretsManager secret value in the creation of EC2 and RDS resources
* Added a variable for the HTTP ingress in order to limit it to only my public IP address

Observations / Learnings:

* Used https://library.tf/ for documentation on the AWS provider, for example how to create [a SecretsManager Resource](https://library.tf/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret)
* Discoverd once again that limits are not always what you would think, for example MariaDB RDS maximum password length is 41 characters.
* AWS CloudTrail was instrumental in tracking down sources of failures. Initially I had a very basic resource definition for the secret and when the resources was re-created after some changes, it failed because the resource was still being deleted on AWS side. I updated `aws_secretsmanager_secret` with additional arguments to make replacing easier and more instant.
* The current solution does not cater for Password Rotation, as there is no easy way to do this with the current set-up. I would like to solve this at some later point, but for now I will just first see how the course proceeds - perhaps there is something about this later.



