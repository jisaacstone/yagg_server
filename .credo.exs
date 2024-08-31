%{
  configs: [
    %{
      name: "default",
      checks: %{
        enabled: [
          {Credo.Check.Readability.ModuleDoc, files: %{excluded: ["test/**/*.ex"]}}
        ]
      }
    }
  ]
}
