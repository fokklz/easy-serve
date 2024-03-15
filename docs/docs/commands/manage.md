# Command `easy-serve manage`

Manage existing instances.

```bash
easy-serve manage <name> <action> [options]
```

## Arguments

Name     | Description                         | Default
---------|-------------------------------------|-----------------------------
`name`   | The name of the instance to manage. | will be prompted using `fzf`
`action` | The action to perform.              | will be prompted using `fzf`

## Options

Name           | Description
---------------|-------------------------------------------------
`-c, --client` | Manage the traefik clients instead of instances.
`-h, --help`   | Show help