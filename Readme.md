My note:

To build and run at the top-level:

```bash
dune build bin/main.exe
_build/default/bin/main.exe
```

Format ocaml: ctrl+shift+p, choose ocamlformat manually

====

Example of telnet:https://medium.com/@aryangodara_19887/tcp-server-and-client-in-ocaml-13ebefd54f60

```
./_build/default/bin/main.exe
```

second terminal:
```bash
telnet localhost 9000

read
0
inc
Counter has been incremented
inc
counter has been incremented
read
1
d
Unknown command
```