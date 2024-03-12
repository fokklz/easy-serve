# Prepare your system

Before you install EasyServe, you need to prepare your server. This includes setting up a domain pointing to your server. If you don't have a domain yet, you can get one from a domain registrar. *refer to the search engine of your choice to find some*

## Supported Operating Systems

OS                | Compatibility
------------------|--------------
Debian 10, 11, 12 | ✅

!!! info "Legend"
    ✅ = Works **out of the box** using the instructions.<br>
    ⚠️ = Requires some **manual adjustments** otherwise usable.<br>

!!! warning "Compatibility Note"
    All other operating systems (not mentioned) may also work, but have not been officially tested.

## Firewall & Ports

Please check if any of EasyServe's standard ports are open and not in use by other applications:

```bash
ss -tlpn | grep -E -w '80|443|2233'
# or:
netstat -tulpn | grep -E -w '80|443|2233'
```

### Default Ports

If you have a firewall in front of mailcow, please make sure that these ports are open for incoming connections:

Service | Port   | Protocol | Container | Veriable
--------|--------|----------|-----------|---------------------------------
HTTP(S) | 80/443 | TCP      | traefik   | `${HTTP_PORT}` / `${HTTPS_PORT}`
SFTP    | 2233   | TCP      | sftp      | `${SFTP_PORT}`