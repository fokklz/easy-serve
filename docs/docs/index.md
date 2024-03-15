# Welcome to the EasyServe

EasyServe is designed to simplify the deployment and maintenance of web services. With Docker at its core, it supports a wide range of applications, focusing on HTTP servers and WordPress sites. EasyServe automates the setup process and incorporates robust security features for a seamless server administration experience.

Read trough the [Prepare your system](get-started/index.md) to get your server ready.

Follow the [Installation guide](get-started/installation.md) to install EasyServe on your server.

Please note that EasyServe is in its early stages of development. If you encounter any issues, we encourage you to open an issue on GitHub.

## General Usage instructions

Once EasyServe is installed on your server, you can begin to utilize its features. Refer to [Commands](command-overview.md) to learn about the available commands.


To access the Traefik dashboard, download the `admin` certificate created during the installation. This can be found in the `certs/clients/admin.client.traefik.pfx` directory. The password for the certificate is provided at the end of the installation process and will need to be added to your browser.

To start using EasyServe, create a new instance with the command:
```bash
easy-serve create
```
You will be prompted to select a template and name your instance, for example, `hello-world`. Once created, the instance can be accessed at `https://hello-world.your-domain.com`. Full domains are supported, and any non-valid entries are considered as subdomains.

To manage your instances, use the command:
```bash
easy-serve manage
```


