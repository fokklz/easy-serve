# Installation

Ensure you read through the [Prepare your system](index.md) to get your server ready.

You can use curl to install EasyServe on your server by loading the installation script and running it. To use a different name, replace the `bash` at the end with `NAME="your-name" bash`.

```bash 
curl -sSL https://easy-serve.flz.direct | bash
```

If you'd rather not use web-based installation, you can also clone the repository and run the `setup.sh` manually from within the cloned directory.

```bash
git clone https://github.com/fokklz/easy-serve.git
cd easy-serve
bash scripts/setup.sh
```

Both methods will install EasyServe and guide you through the setup process.