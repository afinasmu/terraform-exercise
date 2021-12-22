# terraform-exercise

Please write Terraform HCL configuration to generate AWS Infra with these specifications:
a. 1 VPC
b. 1 public subnet
c. 1 private subnet connected to 1 NAT Gateway
d. 1 autoscaling group with config :
minimum 2 EC2 T2.medium instances and max 5 instances, where scaling policy
is CPU >= 45%. Instances must be placed on 1 Private subnet created in
point 3 above.
