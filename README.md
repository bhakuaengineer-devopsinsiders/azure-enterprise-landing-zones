# 🔐 Azure Enterprise Landing Zones (Terraform Engine)
### Production-Grade Microsoft Cloud Adoption Framework (CAF) with Hub-and-Spoke Topology

[![Terraform](https://img.shields.io/badge/Terraform-v1.5%2B-7B42BC?style=for-the-badge&logo=terraform&logoColor=white)](https://www.terraform.io)
[![Azure](https://img.shields.io/badge/Microsoft_Azure-CAF_Enterprise-0078D4?style=for-the-badge&logo=microsoftazure&logoColor=white)](https://azure.microsoft.com)
[![CIS Benchmark](https://img.shields.io/badge/Compliance-CIS_Azure_v2.0-10B981?style=for-the-badge&logo=securityscorecard&logoColor=white)](#compliance)
[![License](https://img.shields.io/badge/License-MIT-blue?style=for-the-badge)](LICENSE)

---

## 🏛️ Architectural Overview

This repository provides an enterprise-ready, declarative Infrastructure-as-Code (IaC) foundation engineered in **Terraform**. It strictly adheres to Microsoft's **Cloud Adoption Framework (CAF)** and implements a hardened **Hub-and-Spoke hybrid topology** supporting 100+ scalable enterprise workloads.

```
                             [ On-Premises Datacenter ]
                                         │
                       (ExpressRoute / Dual S2S VPN Failover)
                                         │
+────────────────────────────────────────▼────────────────────────────────────────+
|                      ENTERPRISE HUB VNet (Central Transit)                      |
|                                                                                 |
|  +───────────────────────────+  +────────────────────+  +────────────────────+  |
|  | Azure Firewall Premium    |  | GatewaySubnet      |  | Centralized        |  |
|  | (TLS / Deep Packet Insp.) |  | (ER / VPN Gateway) |  | Private DNS Zones  |  |
|  +─────────────┬─────────────+  +────────────────────+  +────────────────────+  |
+────────────────|────────────────────────────────────────────────────────────────+
                 │ (Global VNet Peering + UDR 0.0.0.0/0 -> Central Firewall IP)
                 +────────────────────────────────┬───────────────────────────────+
                 │                                                                │
+────────────────▼────────────────────+                 +─────────────────────────▼────────────────────+
|   SPOKE 1: Core Banking & ERP       |                 |   SPOKE 2: Shared Platform & AI Engine       |
|  +────────────────────────────────+ |                 |  +─────────────────────────────────────────+ |
|  | AKS Cluster (Private API)      | |                 |  | Autonomous AI Agent Runners (MCP Host)  | |
|  +────────────────────────────────+ |                 |  +─────────────────────────────────────────+ |
|  | DB Tier (Private Endpoint SQL) | |                 |  | Self-Hosted CI/CD Runners & Bastion     | |
|  +────────────────────────────────+ |                 |  +─────────────────────────────────────────+ |
|  | Azure Key Vault (CMK / HSM)    | |                 |  | Log Analytics & Sentinel SIEM Ingestion | |
|  +────────────────────────────────+ |                 |  +─────────────────────────────────────────+ |
+─────────────────────────────────────+                 +──────────────────────────────────────────────+
```

## ⚡ Key Engineering Patterns

* **Dynamic Block Iteration:** Dynamic generation of subnets, prioritized NSG rules, custom UDR routing tables, and Azure Key Vault access policies eliminating duplicate boilerplate.
* **Complex Data Projections:** Extensive use of `for_each` across maps of typed objects, map merges, and validation rules using regular expressions.
* **Deterministic Traffic Egress:** Force-tunnels `0.0.0.0/0` traffic from Spoke workloads to the Azure Firewall cluster using custom UDRs.
* **Remote State Leasing:** Designed for production state locking inside Azure Blob Storage with customer-managed keys (CMK) and lease locks.

## 🚀 Quickstart & Deployment

1. **Clone the repository:**
   ```bash
   git clone https://github.com/bhakuaengineer-devopsinsiders/azure-enterprise-landing-zones.git
   cd azure-enterprise-landing-zones
   ```

2. **Configure Variables:**
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with your Azure Subscription & Tenant IDs
   ```

3. **Initialize & Validate:**
   ```bash
   terraform init
   terraform validate
   terraform plan -out=tfplan.binary
   ```

4. **Deploy:**
   ```bash
   terraform apply tfplan.binary
   ```

## 🛡️ Security & Compliance
* **Checkov IaC Scanning:** Zero High/Critical findings against the CIS Azure v2.0 benchmark.
* **Least Privilege:** Service principals configured with time-bound PIM assignments.
* **Zero Direct Ingress:** No public IPs on application compute tiers; ingress strictly via Application Gateway / WAF.
