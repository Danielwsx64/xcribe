# Used by "mix format"
[
  import_deps: [:phoenix, :plug],
  inputs: ["{mix,.formatter}.exs", "{bin,config,lib,test}/**/*.{ex,exs}"],
  export: [locals_without_parens: [document: 1, document: 2]]
]
