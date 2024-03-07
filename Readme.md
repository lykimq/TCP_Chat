My note:

To build and run at the top-level:

```bash
dune build bin/main.exe
_build/default/bin/main.exe server --server-addr localhost --port 9000
_build/default/bin/main.exe client --server-addr localhost --port 9000
```

Format ocaml: ctrl+shift+p, choose ocamlformat manually
