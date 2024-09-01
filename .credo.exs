%{
  configs: [
    %{
      name: "default",
      checks: %{
        extra: [
          {Credo.Check.Readability.ModuleDoc, files: %{excluded: ["test/**/*.ex"]}}
        ],
        disabled: [
          {Credo.Check.Refactor.UnlessWithElse, []}
        ]
      }
    }
  ]
}
