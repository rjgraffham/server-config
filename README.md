# RJ's Server Config


My server configuration, defined as kubernetes objects and deployed automatically on push via [Flux][fluxcd].

As of right now it defines a single-node cluster, so it does not benefit from many of the advantages of a cluster, but it leaves future expansion open, and it still benefits from the ability to rely on kubernetes features like rolling updates.


## Motivation

After a number of years administering and maintaining [my server on NixOS][nixos-config], I reached the conclusion that while I wanted to continue tracking my server configuration in version control, NixOS was not an ideal fit for me, primarily due to requiring the full system definition to be built on changes[^1].

Additionally, I ran into a number of applications I wanted to run on my server and which were primarily distributed as OCI containers. While these could potentially be repackaged for NixOS's build system, I did not wish to commit to the maintenance burden of effectively becoming a downstream, so I began migrating my system to run primarily container workloads via podman, using quadlets to integrate them into systemd's service management.

However, while [this iteration of the system][quadlet-config] worked, it was still dependent on me getting the quadlets into place on the system, and I had a lot of unanswered questions on how to effectively keep the system and the repo in sync, so I wanted to move to the repo being the sole source of truth (i.e., gitops).

It was at this point I realized that what I was effectively looking for was a way to orchestrate containerized workloads and deliver them from git, and I remembered reading that Kubernetes is essentially designed for that first part, and that a number of options for kubernetes gitops are available, so I decided to begin building out a kubernetes iteration of my server - this repo is the result.


## Installation

The configuration is intended to be as hands-off as possible, with Flux ensuring that everything present in the repo is present in the cluster. Therefore, the setup amounts to two steps:

1. Install the flux operator (with Helm, as the cluster definition is set up to update the operator through updating Helm releases, and this could conflict with manually applying the manifests):
   ```bash
   helm upgrade -i flux-operator oci://ghcr.io/controlplaneio-fluxcd/charts/flux-operator --namespace flux-system --create-namespace  
   ```

2. Apply the FluxInstance that defines this repo as the cluster's source of truth:
   ```bash
   cd <path-to-repo>
   ```
   ```bash
   kubectl apply -f clusters/homelab/flux-instance.yaml
   ```

Once these steps are run, Flux will work through the components of the cluster definition, reconciling them with the state of the system, and when this is complete, the system will be fully deployed.


---

<!-- Footnotes -->
[^1]: Input hashing and binary caches minimize the actual rebuilds, so it's not as bad as it sounds, but it still at minimum has to evaluate the whole thing. There are probably ways to break out system components so they can be built (and thus updated) separately, but I suspect this would instead run into problems with keeping their nixpkgs sources synchronized.


<!-- Links referenced in the main body -->
<!-- TODO: Update the nixos link here if and when I break out the configs into distinct repos -->
[fluxcd]: https://fluxcd.io/
[nixos-config]: https://github.com/rjgraffham/server-config/tree/main
[quadlet-config]: https://github.com/rjgraffham/server-config/tree/containers
