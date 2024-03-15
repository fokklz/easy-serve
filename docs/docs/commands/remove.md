# Command `easy-serve remove`

Remove a instance.

```bash
easy-serve remove <name> [options]
```

Multiple instances can be removed at once separated by a comma.

## Arguments

Name   | Description                         | Default
-------|-------------------------------------|-----------------------------
`name` | The name of the instance to remove. | will be prompted using `fzf`

## Options

Name          | Description
--------------|-----------------------------------------------------------------------
`-f, --force` | Force remove the instance. With multiple instances, will apply to all.
`-h, --help`  | Show help