# toppan-assignment
toppan-assignment

Scenario 1:

Further improvements to the initial architecture and setup are:
  1. Add AWS WAF (web ACL) to Application Load Balancer to help protect against common web exploits and bots that can affect the availability, compromise security or          consume excessive resources of our web application.
  
  2. Create a bastion host which is located in Public Subnet and configure relevant security group policy which only allowed certain IP address to SSH to bastion host        and also configure the security group port 22 for the Instances in Server Fleet A so it can only allowed the SSH connection from bastion host.
  
  3. Get a SSL certification from AWS Certificate Manager and set SSL offloading at AWS Load Balancer or purchase a SSL certificate so we can have end-to-end HTTPS            connection for our web application. 
