# Easy Serve

Intended to simplify the deployment and maintenance of web services. Utilizing Docker, it supports a variety of applications with a focus on HTTP servers and WordPress sites. Easy Serve automates the setup process and includes robust security features for a hassle-free server administration experience.

## Features

**Automated Setup**: Easy Serve automates the setup process for a variety of web services, including HTTP servers and WordPress sites.<br>
**Security**: Easy Serve includes robust security features to ensure a hassle-free server administration experience.<br>
**Docker**: Easy Serve utilizes Docker to support a variety of applications.<br>
**SFTP**: Easy Serve includes SFTP support for easy file management.<br>
**Custom Templates**: Easy Serve supports custom templates for a variety of applications. basically everything conisting of docker and some variables to configure can be configured to be a template.

## Installation

All you need is a server Debian/Ubuntu based and a Domain. Then you can run the following command to install Easy Serve:

```bash 
curl -sSL https://raw.githubusercontent.com/fokklz/easy-serve/main/install.sh | bash
```

*if you want to use a different name, replace the `bash` at the end with `NAME="your-name" bash`*

Ofcourse you can also clone the repository and run the `setup.sh` manually.

```bash
git clone https://github.com/fokklz/easy-serve.git
cd easy-serve
bash scripts/setup.sh
```

Both methods will install Easy Serve and guide you through the setup process.

## Usage

After the installation, you can download the created `admin` certificate to access the traefik dashboard located in `certs/clients/admin.client.traefik.pfx`. The password needed for the Certificate is printed to the console at the end of the installation. Add the Certificate to your browser.

**This is a very early version of Easy Serve, If you encounter any issues, please open an issue on GitHub.**

To get started create a new instance using the following command:
```bash
easy-serve create
```

you can then select a template and name the instance for example `hello-world`. The instance will be created and you can access it via `https://hello-world.your-domain.com`.
*Full domains are supported, as long as its not valid- its considered a subdomain*

To manage your instances you can run the following command:
```bash
easy-serve
```

## Contributing

Contributions are welcome! If you'd like to improve Easy Serve, feel free to fork the repository and submit a pull request.

## Acknowledgments

- Docker and Docker-compose for providing the container platform.
- Traefik for the simple and powerful reverse proxy solution.

## License

This project is licensed under the Apache License 2.0 - see the [LICENSE](LICENSE) file for details.