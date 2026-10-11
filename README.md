# Route 53 Geolocation Routing Lab

Completed a three-region AWS lab that uses Route 53 geolocation routing to select a regional application endpoint for **[www.nandaxsr.xyz](https://www.nandaxsr.xyz)**.

The domain was purchased from **Namecheap** and delegated to a **Route 53 public hosted zone** by configuring the zone's four AWS nameservers in Namecheap's domain nameserver settings.

## Architecture

![Three-region Route 53 geolocation routing architecture](assests/geo-location.png)

## Infrastructure Overview

| Location | AWS Region | VPC CIDR | Docker Hub Image |
| --- | --- | --- | --- |
| Singapore | `ap-southeast-1` | `10.10.0.0/16` | `mrnanda/singapore-web:1.0` |
| Northern Virginia, USA | `us-east-1` | `10.20.0.0/16` | `mrnanda/usa-web:1.0` |
| Paris, France | `eu-west-3` | `10.30.0.0/16` | `mrnanda/paris-web:1.0` |

Each region contains:

- A VPC with public and private subnets, with two of each across two Availability Zones by default.
- An Internet Gateway and public routes, plus a NAT gateway for outbound internet access from private application servers.
- An internet-facing Application Load Balancer (ALB) in the public subnets.
- Private Ubuntu application instances, with one per region by default and a configurable instance count.
- A public Ubuntu jump host for SSH access to the private application instances.
- An HTTP target group on port **80**, with **`/health.txt`** as its health-check endpoint. Other health-check settings use the provider defaults.

Terraform resources are declared directly in the root directory, with dedicated AWS provider aliases for each region and no child modules.

## Docker Application Deployment

The regional applications were Dockerized using the compact **`nginx:stable-alpine`** image and pushed to Docker Hub. Each image includes its regional welcome page and picture.

Three EC2 user-data templates install Docker, pull the matching image, and start the application container:

| Region | Startup Template |
| --- | --- |
| Singapore | `templates/singapore-user-data.sh.tftpl` |
| USA | `templates/usa-user-data.sh.tftpl` |
| Paris | `templates/paris-user-data.sh.tftpl` |

Containers publish port **80** and use `--restart unless-stopped`. Private instances reach the Docker installer, Ubuntu repositories, and Docker Hub through their regional NAT gateway.

## Security Groups

| Security Group | Inbound Rules | Outbound Rules |
| --- | --- | --- |
| ALB | TCP 80 and 443 from `0.0.0.0/0` | All IPv4 traffic |
| Application | TCP 80 from the ALB security group; TCP 22 from the jump-host security group | All IPv4 traffic |
| Jump host | TCP 22 from `0.0.0.0/0` | All IPv4 traffic |

Application instances have no public IP addresses. Users reach the application through the ALB, while administrators connect through the jump host.

## HTTPS and Certificates

In the completed lab deployment, all three regional ALBs serve HTTPS using certificates requested and issued through **AWS Certificate Manager (ACM)** in their respective regions. Certificates cover the application domain, and TLS terminates at the ALB; the ALB forwards requests to the application on HTTP port 80.

Third-party certificates can also be imported into ACM and attached to the HTTPS listeners. ACM certificates are regional, so a certificate must be requested or imported in each ALB's region. Imported certificates require renewal by the certificate owner. See [AWS certificate import documentation](https://docs.aws.amazon.com/acm/latest/userguide/import-certificate.html).

The deployed ALB HTTP listeners have redirect rules so requests to **`http://www.nandaxsr.xyz`** redirect to **`https://www.nandaxsr.xyz`**.

**Terraform configuration note:** Certificates and Route 53 records are configured manually for this lab. The current Terraform creates an HTTPS listener only when that region's certificate ARN is supplied. Its HTTP listeners currently forward directly to the target groups; the deployed HTTP-to-HTTPS redirect settings described above are not yet represented in those Terraform listener blocks.

## Application Traffic Flow

```text
Route 53 Geolocation Policy       DNS lookup for www.nandaxsr.xyz
             |
             +-- Singapore country --> Singapore ALB (ap-southeast-1)
             |
             +-- United States ------> USA ALB (us-east-1)
             |
             +-- Europe -------------> Paris ALB (eu-west-3)
                                            |
                         DNS returns the selected ALB addresses
                                            |
                                            v
Client connects to selected ALB    HTTPS 443; HTTP 80 redirects to HTTPS
                                            |
                                            v
Regional Internet-facing ALB       Public subnets; TLS termination
                                            |
                                            v
Regional Target Group             HTTP port 80; health check /health.txt
                                            |
                                            v
Ubuntu Application Instances      Private subnets; configurable count
                                            |
                                            v
Docker Container                  Regional welcome page and picture
```

1. **Route 53** evaluates the location associated with the DNS query and returns the selected regional ALB addresses. It handles DNS selection; it does not proxy application requests.
2. The **client** connects to the selected ALB. In the deployed lab, HTTP requests redirect to HTTPS.
3. The **regional ALB** terminates HTTPS and forwards application requests to healthy targets on port 80.
4. The **private Ubuntu instances** receive application traffic only from the ALB security group.
5. The **Docker containers** serve the corresponding Singapore, USA, or Paris welcome page.

## VPN Verification

The completed lab was tested through VPN endpoints:

| VPN Location | Selected AWS Endpoint | Expected Page |
| --- | --- | --- |
| United States | Northern Virginia (`us-east-1`) | USA / New York welcome page |
| Europe | Paris (`eu-west-3`) | Paris welcome page |
| Singapore | Singapore (`ap-southeast-1`) | Singapore welcome page |

The Singapore geolocation record matches **Singapore as a country**, rather than the entire Asian continent. With no matching record or **Default** record, queries identified as coming from other Asian countries receive no DNS answer. This controls DNS selection; it does not block direct access to an ALB endpoint.

VPN results depend on the location Route 53 identifies from the DNS query's source or supported EDNS client-subnet information. A VPN's advertised location alone does not guarantee the DNS query uses that location. See [AWS geolocation routing documentation](https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/routing-policy-geo.html).

## Configurable Application Capacity

Set application counts and disk size in `terraform.tfvars`:

```hcl
singapore_app_instance_count = 2
usa_app_instance_count       = 2
paris_app_instance_count     = 2
app_root_volume_size         = 20
```

Instances are distributed across the region's private subnets, and every instance is registered with its ALB target group. With the default two private subnets, two application instances run in different Availability Zones. Subnet counts follow the lengths of the regional public/private CIDR lists.

These are individual EC2 instances, not an Auto Scaling group. The single NAT gateway per region remains an availability limitation even when application instances span multiple Availability Zones.
