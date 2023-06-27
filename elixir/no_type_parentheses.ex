defmodule Credo.Check.NoTypeParentheses do
  use Credo.Check,
    base_priority: :low,
    category: :consistency,
    explanations: [
      check: """
      Don't use parentheses for local types.

          # not preferred
          @type local_type :: integer()
          @spec func(local_type()) :: A.Remote.type()

          # preferred
          @type local_type :: integer
          @spec func(local_type) :: A.Remote.type()
      """
    ]

  @doc false
  @impl true
  def run(%SourceFile{} = source_file, params) do
    Credo.Code.prewalk(source_file, &traverse(&1, &2, IssueMeta.for(source_file, params)))
  end

  defp traverse(
         {:@, _, [{kind, _, [{:"::", _, [name_ast, _] = types_ast}]}]},
         issues,
         issue_meta
       )
       when kind in [:type, :typep, :spec] do
    {name, name_meta, name_args} = name_ast

    # Disallow empty parameters in `@type t() :: ...`
    {types_ast, issues} =
      if name_args == [] do
        specs_or_type = (kind == :spec && "Specs") || "Types"
        msg = "#{specs_or_type} should not have empty parameters."
        {tl(types_ast), [issue(issue_meta, update_column(name_meta, name), msg) | issues]}
      else
        {types_ast, issues}
      end

    issues = Credo.Code.prewalk(types_ast, &in_types(&1, &2, issue_meta), issues)

    {types_ast, issues}
  end

  defp traverse(ast, issues, _) do
    {ast, issues}
  end

  defp in_types({name, meta, []} = ast, issues, issue_meta) when is_atom(name) and name != :%{} do
    {ast, [issue(issue_meta, update_column(meta, name)) | issues]}
  end

  defp in_types(ast, issues, _issue_meta) do
    {ast, issues}
  end

  defp update_column(ast_meta, name),
    do: ast_meta |> update_in([:column], &(&1 + String.length("#{name}")))

  defp issue(issue_meta, ast_meta) do
    msg = "Types should not have parentheses."
    issue(issue_meta, ast_meta, msg)
  end

  defp issue(issue_meta, ast_meta, msg) do
    format_issue(issue_meta, message: msg, line_no: ast_meta[:line], column: ast_meta[:column])
  end
end
