
# Homelab <br>

I developing my Homelab. I build Kubernetes K8s on Debian Server. I choose it due to stability.
To manage K8s, I selected Flux Cd - GitOps. All cluster resourves are installed by Flux.
To achive simialar UX to ArgoCD, I set up Headlamp.


### Dashboard screen

<img width="1449" height="785" alt="obraz" src="https://github.com/user-attachments/assets/8e614c25-2928-4086-aa73-4bcf79a0602d" />

### Hardware

- 1 × DELL Latitude 5480:
    - CPU: `Intel(R) Core(TM) i5-6300U (4) @ 3.00 GHz`
    - RAM: `16GB`
    - SSD: `256GB`
- 2 × HP t620 Quad Core TC:
    - CPU: `AMD GX-217GA SOC with Radeon(tm) HD Graphics (2) @ 1.65 GHz`
    - RAM: `8GB`
    - SSD: `128GB`
- TP-Link `TL-SG108` switch:
    - Ports: `4`
    - Speed: `100Mbps`

### Master node 

<img width="717" height="346" alt="obraz" src="https://github.com/user-attachments/assets/19778977-3db7-4500-95f4-76b49a4fd3cb" />

<pre>     _,met$$$$$gg.          sidor@debian
     ,g$$$$$$$$$$$$$$$P.       ------------
   ,g$$P""       """Y$$.".     OS: Debian GNU/Linux 13 (trixie) x86_64
  ,$$P'              `$$$.     Host: Latitude 5480
',$$P       ,ggs.     `$$b:    Kernel: Linux 6.12.63+deb13-amd64
`d$$'     ,$P"'   .    $$$     Uptime: 11 days, 22 hours, 34 mins
 $$P      d$'     ,    $$P     Packages: 1608 (dpkg)
 $$:      $$.   -    ,d$$'     Shell: bash 5.2.37
 $$;      Y$b._   _,d$P'       Display (IVO057E): 1366x768 @ 60 Hz in 14" [Built-in]
 Y$$.    `.`"Y$$$$P"'          Cursor: Adwaita
 `$$b      "-.__               Terminal: /dev/pts/0
  `Y$$b                        CPU: Intel(R) Core(TM) i5-6300U (4) @ 3.00 GHz
   `Y$$.                       GPU: Intel HD Graphics 520 @ 1.00 GHz [Integrated]
     `$$b.                     Memory: 9.67 GiB / 15.26 GiB (63%)
       `Y$$b.                  Swap: Disabled
         `"Y$b._               Disk (/): 29.90 GiB / 221.75 GiB (13%) - ext4
             `""""             Local IP (enp0s31f6): 192.168.0.110/24
                               Battery (DELL GD1JP65): 100% [AC Connected]
                               Locale: pl_PL.UTF-8   </pre>

### Master worker node1 

<img width="717" height="346" alt="obraz" src="https://github.com/user-attachments/assets/8068c12d-4037-4c3d-a58c-2a728b2c47b4" />

<pre>           _,met$$$$$gg.          sidor@node1
     ,g$$$$$$$$$$$$$$$P.       -----------
   ,g$$P""       """Y$$.".     OS: Debian GNU/Linux 13 (trixie) x86_64
  ,$$P'              `$$$.     Host: HP t620 Quad Core TC
',$$P       ,ggs.     `$$b:    Kernel: Linux 6.12.63+deb13-amd64
`d$$'     ,$P"'   .    $$$     Uptime: 16 days, 23 hours, 27 mins
 $$P      d$'     ,    $$P     Packages: 1601 (dpkg)
 $$:      $$.   -    ,d$$'     Shell: bash 5.2.37
 $$;      Y$b._   _,d$P'       Cursor: Adwaita
 Y$$.    `.`"Y$$$$P"'          Terminal: /dev/pts/0
 `$$b      "-.__               CPU: AMD GX-415GA SOC with Radeon(tm) HD Graphics (4) @ 1.50 GHz
  `Y$$b                        GPU: AMD Radeon HD 8330E [Discrete]
   `Y$$.                       Memory: 3.01 GiB / 7.20 GiB (42%)
     `$$b.                     Swap: Disabled
       `Y$$b.                  Disk (/): 20.51 GiB / 109.81 GiB (19%) - ext4
         `"Y$b._               Local IP (enp2s0): 192.168.0.111/24
             `""""             Locale: pl_PL.UTF-8         </pre>


### Master worker node2

<img width="717" height="346" alt="obraz" src="https://github.com/user-attachments/assets/372eb195-733a-47c2-8e5e-259e984e58ec" />

<pre>          _,met$$$$$gg.          sidor@node2
     ,g$$$$$$$$$$$$$$$P.       -----------
   ,g$$P""       """Y$$.".     OS: Debian GNU/Linux 13 (trixie) x86_64
  ,$$P'              `$$$.     Host: HP t620 Dual Core TC
',$$P       ,ggs.     `$$b:    Kernel: Linux 6.12.63+deb13-amd64
`d$$'     ,$P"'   .    $$$     Uptime: 16 days, 23 hours, 26 mins
 $$P      d$'     ,    $$P     Packages: 1600 (dpkg)
 $$:      $$.   -    ,d$$'     Shell: bash 5.2.37
 $$;      Y$b._   _,d$P'       Cursor: Adwaita
 Y$$.    `.`"Y$$$$P"'          Terminal: /dev/pts/0
 `$$b      "-.__               CPU: AMD GX-217GA SOC with Radeon(tm) HD Graphics (2) @ 1.65 GHz
  `Y$$b                        GPU: AMD Radeon HD 8280E [Discrete]
   `Y$$.                       Memory: 3.12 GiB / 7.20 GiB (43%)
     `$$b.                     Swap: Disabled
       `Y$$b.                  Disk (/): 22.22 GiB / 109.81 GiB (20%) - ext4
         `"Y$b._               Local IP (enp1s0): 192.168.0.112/24
             `""""             Locale: pl_PL.UTF-8          </pre>

   
######################################################################################

## Router TP-LINK TL-WR841N

<img width="900" height="252" alt="obraz" src="https://github.com/user-attachments/assets/77ca5d63-5df9-45f3-9fce-4c3e7aa301dc" />
<img width="880" height="809" alt="obraz" src="https://github.com/user-attachments/assets/86371c30-7ad1-40a3-bf87-73a7d225064f" />

## Dell Latitude 5480 - 1 PCS + HP t620 Quad Core TC - 2 PCS

<img width="817" height="1109" alt="obraz" src="https://github.com/user-attachments/assets/f6a4146f-384f-4d19-9755-94e2d342ce1e" />

## TP-SG108E  - 1 PSC

<img width="211" height="767" alt="obraz" src="https://github.com/user-attachments/assets/cf5bfece-8b15-444d-accf-96ddeb94b94d" />

## GRAFANA master node 1

<img width="1435" height="780" alt="obraz" src="https://github.com/user-attachments/assets/8e3609ab-02a2-4bed-a681-e5cbf50beb7b" />

## GRAFANA worker node 1

<img width="1435" height="780" alt="obraz" src="https://github.com/user-attachments/assets/99bfc7e5-731b-49a5-b548-19792b006497" />

## GRAFANA worker node 2

<img width="1435" height="780" alt="obraz" src="https://github.com/user-attachments/assets/34e00e39-dfb3-4ed9-84bf-8101b73ea9b0" />

# Headlamp Fluxcd = ArgoCD UI

<img width="1446" height="309" alt="obraz" src="https://github.com/user-attachments/assets/2e426d50-901b-49c1-b9f6-55638f490a71" />

## Headlamp Fluxcd 
### Filter components

<img width="1464" height="418" alt="obraz" src="https://github.com/user-attachments/assets/78637359-cfad-45fe-9969-df5455e10fc1" />

## Headlamp Fluxcd 
### Filter components and draw resources 

<img width="1471" height="641" alt="obraz" src="https://github.com/user-attachments/assets/b6615a01-9b87-4f51-900c-173df628326f" />



This project utilizes [Infrastructure as Code](https://en.wikipedia.org/wiki/Infrastructure_as_code) and [GitOps](https://www.weave.works/technologies/gitops) to automate provisioning, operating, and updating self-hosted services in my homelab.
It can be used as a highly customizable framework to build your own homelab.

> **What is a homelab?**
>
> Homelab is a laboratory at home where you can self-host, experiment with new technologies, practice for certifications, and so on.
> For more information, please see the [r/homelab introduction](https://www.reddit.com/r/homelab/wiki/introduction) and the
> [Home Operations Discord community](https://discord.gg/home-operations) (formerly known as [k8s-at-home](https://k8s-at-home.com)).

## Overview

This project is still in the experimental stage, and I don't use anything critical on it.
Expect breaking changes that may require a complete redeployment.
I use it as a tool to prep to CKA Exam.


- [x] Common applications: Linkding, Linkwarden, Homarr
- [] Common applications: Gitea, Jellyfin, Paperless...
- [x] Automated bare metal IP provisioning with Metal LB
- [x] Confirmed bash scripts to install Kubernetes on control plane and worker nodes.
- [] Automated Kubernetes installation and management
- [x] Installing and managing applications using GitOps
- [x] Expose services to the internet securely with [Cloudflare Tunnel](https://www.cloudflare.com/products/tunnel/)
- [] CI/CD platform
- [x] Distributed storage
- [x] Monitoring and alerting
- [x] Automated backup

Some article and screenshots on my blog.

##  Blogerr Links:
- [Kubespray Homelab K8s](https://asidor23.blogspot.com/2025/10/kubespray-homelab.html)
- .....

### Tech stack

<table>
    <tr>
        <th>Logo</th>
        <th>Name</th>
        <th>Description</th>
    </tr>
    <tr>
        <td><img width="32" src="https://avatars.githubusercontent.com/u/13629408"></td>
        <td><a href="https://kubernetes.io">Kubernetes</a></td>
        <td>Container-orchestration system, the backbone of this project</td>
    </tr>
    <tr>
        <td><img width="32" src="https://avatars.githubusercontent.com/fluxcd"></td>
        <td><a href="https://fluxcd.io/">Flux CD</a></td>
        <td>GitOps tool built to deploy applications to Kubernetes</td>
    </tr>
    <tr>
        <td><img width="32" src="https://avatars.githubusercontent.com/external-secrets"></td>
        <td><a href="https://external-secrets.io/latest/">External Secret Operatorr</a></td>
        <td>Cloud native certificate management</td>
    </tr>   
    <tr>
        <td><img width="32" src="https://avatars.githubusercontent.com/GoogleCloudPlatform"></td>
        <td><a href="https://cloud.google.com/security/products/secret-manager?hl=pl">Google Secret Manager</a></td>
        <td>Google Cloud native secret Manager management</td>
    </tr>
    <tr>
        <td><img width="32" src="https://github.com/jetstack/cert-manager/raw/master/logo/logo.png"></td>
        <td><a href="https://cert-manager.io">cert-manager</a></td>
        <td>Cloud native certificate management</td>
    </tr>
    <tr>
        <td><img width="32" src="https://avatars.githubusercontent.com/u/21054566?s=200&v=4"></td>
        <td><a href="https://cilium.io">Cilium</a></td>
        <td>eBPF-based Networking, Observability and Security (CNI, LB, Network Policy, etc.)</td>
    </tr>
    <tr>
        <td><img width="32" src="https://avatars.githubusercontent.com/u/314135?s=200&v=4"></td>
        <td><a href="https://www.cloudflare.com">Cloudflare</a></td>
        <td>DNS and Tunnel</td>
    </tr>
    <tr>
        <td><img width="32" src="https://avatars.githubusercontent.com/debian"></td>
        <td><a href="https://www.debian.org/">Debian Server</a></td>
        <td>Base OS for Kubernetes nodes</td>
    </tr>
    <tr>
        <td><img width="32" src="https://grafana.com/static/img/menu/grafana2.svg"></td>
        <td><a href="https://grafana.com">Grafana</a></td>
        <td>Observability platform</td>
    </tr>
    <tr>
        <td><img width="32" src="https://helm.sh/img/helm.svg"></td>
        <td><a href="https://helm.sh">Helm</a></td>
        <td>The package manager for Kubernetes</td>
    </tr>
    <tr>
        <td><img width="32" src="https://github.com/grafana/loki/blob/main/docs/sources/logo.png?raw=true"></td>
        <td><a href="https://grafana.com/oss/loki">Loki</a></td>
        <td>Log aggregation system</td>
    </tr>
    <tr>
        <td><img width="32" src="https://avatars.githubusercontent.com/traefik"></td>
        <td><a href="https://doc.traefik.io/">Traefik</a></td>
        <td>Kubernetes Ingress Controller</td>
    </tr>
    <tr>
        <td><img width="32" src="https://avatars.githubusercontent.com/u/3380462"></td>
        <td><a href="https://prometheus.io">Prometheus</a></td>
        <td>Systems monitoring and alerting toolkit</td>
    </tr>
    <tr>
        <td><img width="32" src="https://docs.renovatebot.com/assets/images/logo.png"></td>
        <td><a href="https://www.whitesourcesoftware.com/free-developer-tools/renovate">Renovate</a></td>
        <td>Automatically update dependencies -tbd </td>
    </tr>
</table>



<img width="626" height="598" alt="obraz" src="https://github.com/user-attachments/assets/5e19c477-bf71-4706-af6e-632862b2d892" />

