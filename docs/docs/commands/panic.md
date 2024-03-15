# Command `easy-serve panic`

Overwrite all existing certificates and remove all clients.

```shell
easy-serve panic [options]
```


## Options

Name           | Description
---------------|-------------------------------------------------------------
`--no-restart` | Do not restart. Warning: will break traefik if not restarted
`-f, --force`  | Skip the confirm dialog
`-h, --help`   | Show help