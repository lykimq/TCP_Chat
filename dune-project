(lang dune 3.0)

(name TCP_Chat)

(version 0.1.0)

(generate_opam_files true)

(source
 (github username/reponame))

(authors "Author Name")

(maintainers "Maintainer Name")

(license LICENSE)

(documentation https://url/to/documentation)

(package
 (name TCP_Chat)
 (synopsis "TCP Chat Application")
 (description "A simple TCP chat application with server and client modes")
 (depends
  (ocaml (>= 4.14.0))
  (dune (>= 3.0))
  (lwt (>= 5.6.1))
  (lwt_ppx (>= 2.1.0))
  (logs (>= 0.7.0))
  (fmt (>= 0.9.0))
  (ocamlformat (>= 0.26.1))
  (cmdliner (>= 1.1.0))
  (alcotest :with-test)
  (alcotest-lwt :with-test)))

; See the complete stanza docs at https://dune.readthedocs.io/en/stable/dune-files.html#dune-project
