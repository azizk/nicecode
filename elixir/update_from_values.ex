defmodule UpdateFromValues do
  # Author: Aziz Köksal
  # License: MIT

  @moduledoc """
  A solution for Ecto's lack of `SQL: "UPDATE FROM (VALUES (...))"`.

  ## Example

  ```sql
  WITH "values" AS (SELECT * FROM jsonb_populate_recordset(NULL::"posts", to_jsonb($1::jsonb[])))
  UPDATE "posts" AS p0 SET "title" = v1."title", "updated_at" = now()
  FROM "values" AS v1 WHERE (v1."id" = p0."id")
  ```
  """
  import Ecto.Query
  alias MyApp.{Repo, Post, Comment}

  defmacro with_cte_values(schema, cte_name, values) do
    quote do
      with_cte_values(unquote(schema), unquote(schema), unquote(cte_name), unquote(values))
    end
  end

  defmacro with_cte_values(queryable, schema, cte_name, values) do
    source = inspect(Macro.expand(schema, __ENV__).__schema__(:source))

    quote do
      Ecto.Query.with_cte(unquote(queryable), unquote(cte_name),
        as:
          fragment(
            # NB: unfortunately the type `NULL::source` cannot be parameterized.
            unquote("SELECT * FROM jsonb_populate_recordset(NULL::#{source}, to_jsonb(?))"),
            ^unquote(values) |> type({:array, :map})
          )
      )
    end
  end

  @spec with_values(module, [map], binary) :: Ecto.Query.t()
  def with_values(struct, values, cte_name \\ "values")
  def with_values(Post, values, cte_name), do: with_cte_values(Post, ^cte_name, values)
  def with_values(Comment, values, cte_name), do: with_cte_values(Comment, ^cte_name, values)

  def with_values(struct, _values, _cte_name),
    do: raise(ArgumentError, message: "unhandled #{inspect(struct)}")

  @type value_map :: %{required(:id) => pos_integer}

  @spec update_from_values_query(module, [value_map], binary) :: Ecto.Query.t()
  def update_from_values_query(schema, values, cte_name \\ "values") do
    with_values(schema, values, cte_name)
    |> join(:inner, [x], ^cte_name, on: [id: x.id], as: :values)
  end

  @spec update_posts_from([value_map]) :: {pos_integer, nil}
  def update_posts_from(values) do
    update_from_values_query(Post, values)
    |> update([values: v], set: [title: v.title, updated_at: fragment("now()")])
    |> where_if_any_distinct([:title])
    |> Repo.update_all([])
  end

  defmacro distinct?(a, b) do
    quote(do: fragment("? is distinct from ?", unquote(a), unquote(b)))
  end

  @spec where_if_any_distinct(Ecto.Query.t(), [atom]) :: Ecto.Query.t()
  def where_if_any_distinct(query, fields) do
    [first | rest] = fields

    is_any_field_distinct =
      rest
      |> Enum.reduce(
        dynamic([x, values: v], distinct?(field(x, ^first), field(v, ^first))),
        &dynamic([x, values: v], distinct?(field(x, ^&1), field(v, ^&1)) or ^&2)
      )

    query |> where(^is_any_field_distinct)
  end
end
