# Echo client identity: rollout and recovery

This change carries the source IP/port observed by OCI through F5 NGINX into
echo's request logs. Terraform owns the Shared Platform Service; Argo CD owns
echo. The agreed scope permits a maintenance interruption of the shared ingress
and a changed public IP if recovery requires replacement. This runbook is a
feature rollout, separate from the F5 version-upgrade procedure.

Code preparation and read-only validation do not publish images, synchronize
Argo Applications, apply Terraform, or authorize deletion of live resources.
Review the concrete release and full plan before executing the steps below.

## Contract

| Hop | Identity source and trust |
| --- | --- |
| OCI LB → F5 | PROXY protocol v2; F5 trusts the verified LB source subnet(s), currently `10.0.8.0/24`. |
| F5 → echo | `X-Echo-Client-IP: $proxy_protocol_addr` and `X-Echo-Client-Port: $proxy_protocol_port`, overwritten by F5 for every echo request. Empty metadata removes the headers. |
| echo | Accept these dedicated headers only from an immediate peer in `TRUSTED_PROXY_CIDRS`, currently `10.0.4.0/22`. |

These private CIDRs trust all internal callers in those networks. They do not
authenticate individual ingress pods, and there is no new NetworkPolicy or
policy enforcement engine in this change. Public callers cannot choose the
authoritative values via HTTP headers. Raw request headers continue to appear
in diagnostic logs and may contain caller-supplied data.

The app preserves `remoteAddr` and adds `clientIp` plus optional numeric
`clientPort`. Invalid/missing IP metadata omits both fields; an invalid/missing
port omits only the port. Responses continue normally. Existing successful
requests log at debug level; this deployment already uses `LOG_LEVEL=debug`.
The source port is not `X-Forwarded-Port` (normally the destination port 443).

## Preflight and release gate

1. Review the echo source, chart, active root Application, and Terraform diffs.
   Run `go test -race ./...` and `go vet ./...` in the echo source repository.
   Publish its reviewed commit as `ghcr.io/invine/echo:v0.0.4` using the existing
   release workflow. Verify the registry digest and `linux/arm64` availability
   before merging the active Application's new image pin. This task has not
   created or pushed that tag. If that tag is already used for another release,
   select a new immutable tag and update the reviewed pin; never overwrite it.
2. Capture Service UID, ClusterIP, ports/NodePorts, external IP, selectors,
   EndpointSlices, Helm/chart/controller versions and existing Helm values.
   Verify the running pair is chart `2.6.4` / controller `5.5.4`. Do not combine
   this feature activation with an ingress version upgrade.
3. Inspect actual OCI listeners, backend sets, backend health and LB subnet(s).
   Verify TCP listeners forward TLS to NGINX and no other intermediary changes
   the public source before OCI. Confirm source CIDRs against Live State. The
   initial investigation inspected Kubernetes and generated NGINX configuration,
   not the actual OCI listener configuration. Stop on a mismatch.
4. Record all served hostnames and their expected HTTP/TLS/authentication and
   websocket behavior. Include Argo CD, echo, Vaultwarden, relay portal/WSS and
   any additional live Ingress or F5 routing resource. Verify this baseline
   before changing anything.
5. Check OCI backend health-check behavior and NGINX readiness/liveness endpoints
   before activation. Checks must remain usable when the application listeners
   require PROXY protocol. Retain the dedicated controller health ports and
   Service `externalTrafficPolicy: Local`.
6. Verify direct Kubernetes/OCI administration works without the shared ingress;
   Argo's public UI may be unavailable during the cutover. Save evidence under a
   restrictive umask outside Git. Use the existing kubeconfig explicitly, e.g.
   `export KUBECONFIG="$PWD/prod-cluster_kubeconfig"` from the infrastructure
   repository root.

## Install header overwrites before trusting them

The Bootstrap Seed syncs automatically; the echo child Application is manually
synchronized. After the reviewed image and chart changes are published, resolve
and record the exact chart Git commit. Use that same revision for both syncs;
do not let an intervening `main` update enter this rollout.

First synchronize **only** the echo Ingress through Argo CD:

```sh
: "${CHART_REVISION:?Set CHART_REVISION to the reviewed k8s-charts commit}"
argocd app sync echo-app --revision "$CHART_REVISION" \
  --resource networking.k8s.io:Ingress:echo-app
```

On every ready ingress pod, inspect `nginx -T` and the echo virtual server. It
must contain exactly the two dedicated `proxy_set_header` directives in the
contract, with no duplicate or inherited override. Check controller events for
annotation validation/reload errors. The Ingress having an external IP does not
prove that NGINX accepted the annotation.

Only after this check, sync the full echo Application at the same revision and
wait for its new Deployment to become ready:

```sh
argocd app sync echo-app --revision "$CHART_REVISION"
kubectl -n echo rollout status deployment/echo-app --timeout=5m
```

Before OCI PROXY activation, test a request with forged dedicated headers. Echo
must omit the client fields because the NGINX PROXY variables are empty. It must
still log `remoteAddr` and return its existing response. This sequencing avoids
a period in which a new app trusts headers an old ingress passes through.

## Prepare and approve the platform cutover

Persist these settings in the existing protected `platform.tfvars`, preserving
every other value. Do not rely on temporary command-line overrides for an
applied deployment: future full plans must retain the same settings.

```hcl
nginx_ingress_version        = "2.6.4"
nginx_proxy_protocol_enabled = true
nginx_lb_trusted_cidrs        = ["10.0.8.0/24"]
```

From the repository root, create a fresh full plan. Do not use `-target`.

```sh
umask 077
mkdir -p .scratch/echo-client-identity/evidence
./scripts/terraform-local -chdir=platform plan -input=false \
  -var-file=../platform.tfvars \
  -out=../.scratch/echo-client-identity/evidence/platform.tfplan
```

Expected change: only an in-place `helm_release.nginx_ingress` update. Render
its before/after values with chart 2.6.4 and inspect the resource diff: the LB
Service gains only the PROXY-v2 annotation, and the F5 ConfigMap gains native
`proxy-protocol`, `real-ip-header`, `set-real-ip-from` and `real-ip-recursive`
entries. Service identity, traffic policy, controller DaemonSet and selectors
must remain stable. Reject unrelated changes, secrets, replacements or DNS
actions. Record the plan checksum, image digest, Git revisions, endpoint
baseline, maintenance window and recovery route; obtain approval for this exact
package before applying.

The preparation-time plan used command-line overrides to preview this change;
it did not modify `platform.tfvars`. Regenerate after persisting the settings.

## Maintenance cutover and acceptance

Apply the reviewed saved plan during the agreed window:

```sh
./scripts/terraform-local -chdir=platform apply \
  ../.scratch/echo-client-identity/evidence/platform.tfplan
```

The controller's ConfigMap reload and OCI listener reconciliation are not atomic.
Requests can fail until both sides agree. Helm reporting success or pods being
Ready is insufficient. Verify every OCI listener reports PROXY v2 and every
ready NGINX instance has matching `listen ... proxy_protocol` directives,
`real_ip_header proxy_protocol` and the expected trusted LB CIDRs. Check OCI
backends, Service identity/IP, ready endpoints and NGINX reload errors.

From an external client with an independently known public source, send uniquely
labelled GET, POST and `/ping` requests, including the missing-message and
invalid-JSON paths. Verify the established responses and logs. For example:

```sh
curl --fail-with-body \
  -H 'X-Echo-Client-IP: 192.0.2.99' \
  -H 'X-Echo-Client-IP: 192.0.2.98' \
  -H 'X-Echo-Client-Port: 1' \
  -H 'X-Forwarded-For: 192.0.2.99' \
  -H 'X-Real-IP: 192.0.2.99' \
  'https://echo.everk8s.duckdns.org/?message=client-identity-spoof-check'
```

The authoritative `clientIp` must equal the known public source, never either
spoofed value, the LB private address or ingress pod IP. `remoteAddr` must still
identify the ingress connection. If present, the source port must be a valid
client port supplied by PROXY metadata; corroborate it using a controlled public
client/edge observation. A local `curl --local-port` value alone is not proof
when NAT may translate it. Do not claim a server port or missing value is the
client port.

Rerun the complete shared-endpoint HTTP/TLS/authentication/websocket baseline.
Include any ACME HTTP-01 routes present during the window. Record all results
and only then close the rollout issue.

## Recovery

OCI retains the last enabled PROXY setting when the annotation is removed or
emptied. **Do not set the feature flag false, restore old Helm values, or run
`helm rollback` against this existing LB as a routine rollback.** That can leave
the LB sending PROXY bytes to NGINX listeners that no longer accept them.

1. If only echo logging fails, keep LB and ingress protocol settings aligned.
   Disable echo's metadata consumption or restore its previous image through a
   reviewed Argo change. Public request routing can continue with PROXY enabled.
   Keep the header-overwrite annotation until no app trusts the headers.
2. If shared traffic fails, inspect both ends through the direct administration
   path. Keep the LB annotation and F5 PROXY listener configuration enabled and
   correct the failing side through a reviewed full Terraform plan. Check all
   controller replicas and actual OCI reconciliation status. Do not repeatedly
   toggle the flag or mistake pod readiness for LB compatibility.
3. If forward recovery is not viable, stop and prepare a separately reviewed
   Service/LB replacement plan using the captured baseline. Identify the exact
   resources, deletion/recreation order, Helm/Terraform reconciliation steps,
   chosen protocol on the replacement and expected new IP before approving it.
   Do not replace the whole Helm release merely to replace its Service. The
   normal cutover plan does not authorize deleting either resource. Preserve
   the controller identities and explicitly account for increased downtime and
   DNS caching. An old saved plan is not a replacement procedure.
4. If recovery changes the LB IP, update DuckDNS explicitly. The existing
   `null_resource.duckdns_update` has no IP-change trigger. Once the replacement
   Service is healthy, prepare a full plan with
   `-replace=null_resource.duckdns_update`, review the observed new Service IP
   and require that the only intended extra action is rerunning this updater.
   Apply only after approval, verify DuckDNS returned `OK`, and independently
   resolve every affected hostname to the new address. Keep the token out of
   terminal history and evidence. Changing the LB alone does not update DNS.
5. Rerun the entire endpoint and identity gate before declaring recovery complete.

## Primary references

- [Oracle OKE PROXY protocol configuration and persistent listener setting](https://docs.oracle.com/en-us/iaas/Content/ContEng/Tasks/contengconfiguringloadbalancersnetworkloadbalancers-subtopic.htm)
- [F5 native ConfigMap parameters](https://docs.nginx.com/nginx-ingress-controller/configuration/global-configuration/configmap-resource/)
- [F5 proxy header annotation](https://docs.nginx.com/nginx-ingress-controller/configuration/ingress-resources/advanced-configuration-with-annotations/)
- [NGINX real-IP module](https://nginx.org/en/docs/http/ngx_http_realip_module.html)
- [Argo CD selective resource sync](https://argo-cd.readthedocs.io/en/stable/user-guide/commands/argocd_app_sync/)
