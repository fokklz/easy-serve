# Command `easy-serve create`

Create a new instance from a template.

```shell
easy-serve create <template> <domain> [name] [options]
```

## Arguments

Additional arguments specific to the template will be prompted for.

Name       | Description               | Default
-----------|---------------------------|-----------------------------------------------------------
`template` | The template to use.      | will be prompted using `fzf`
`domain`   | The domain to use.        | -
`name`     | The name of the instance. | inferred from `domain` taking the first part of the domain

To simplify the creation of sub-domain instances, the `domain` argument can be only a name, the set domain for EasyServe will be appended to the name.

## Options

Name          | Description
--------------|----------------------------
`--no-sftp`   | Do not create SFTP user
`-f, --force` | Overwrite existing instance
`-h, --help`  | Show help