#! /usr/bin/env elixir
defmodule Common do
  @doc "Like a case statement but without the do-expression."
  defmacro then(check_exp, case_exp) do
    quote do
      case unquote(check_exp) do
        unquote(case_exp)
      end
    end
  end

  @doc "Extracts the 2nd element of a tuple when the first matches `atom`."
  defmacro atom_or(atom, tuple_exp, or_exp) do
    quote do
      case unquote(tuple_exp) do
        {unquote(atom), x} -> x
        _ -> unquote(or_exp)
      end
    end
  end

  defmacro ok_or(ok_exp, or_exp), do: atom_or(:ok, ok_exp, or_exp)
  defmacro e_or(ok_exp, or_exp), do: atom_or(:error, ok_exp, or_exp)

  @doc "A cond statement usable in pipe statements."
  defmacro branch(expr, match_expr, do: clauses) do
    quote do
      case unquote(expr) do
        unquote(match_expr) = x ->
          cond do
            unquote(clauses ++ quote(do: (true -> x)))
          end

        x ->
          x
      end
    end
  end

  @doc "A case statement including a default clause returning the unmatched value."
  defmacro dcase(expr, do: clauses) do
    quote do
      case unquote(expr), do: unquote(clauses ++ quote(do: (x -> x)))
    end
  end

  @doc "An if-statement with a match operator condition."
  defmacro ifm({:<-, _, [l, r]}, do: do_body) do
    quote do
      case unquote(r) do
        unquote(l) -> unquote(do_body)
        _ -> nil
      end
    end
  end

  @doc "An if-statement with a match operator condition."
  defmacro ifm({:<-, _, [l, r]}, do: do_body, else: else_body) do
    quote do
      case unquote(r) do
        unquote(l) -> unquote(do_body)
        _ -> unquote(else_body)
      end
    end
  end

  @doc "The match? function as an operator."
  defmacro pattern <~ expression do
    quote do
      match?(unquote(pattern), unquote(expression))
    end
  end
end

defmodule TestCommon do
  import Common
  import ExUnit.Assertions

  res =
    ifm {:ok, x} <- {:ok, 10} do
      x
    end

  assert res == 10

  res =
    ifm {:ok, x} <- {:no, 10} do
      x
    else
      3
    end

  assert res == 3

  {:ok, 5}
  |> branch {:ok, b} do
    b == 5 -> 6
  end
  |> IO.inspect(label: "branch({:ok, 5})")

  {:ok, 4}
  |> branch {:ok, xY} do
    xY < 1 ->
      IO.puts("x is less than one")
      2

    xY == 1 ->
      IO.puts("x equals one")
      3

    xY == 4 ->
      -7
  end
  |> branch xY do
    xY == -6 -> IO.puts("branch xY: #{xY}")
  end
  |> IO.inspect(label: "branch")

  IO.inspect(binding(), label: "binding")
  # IO.inspect(xy, label: "branch")

  {:ok, 123}
  |> then(
    (
      {:err, _} -> 1
      {:ok, _} -> 2
    )
  )
  |> IO.inspect(label: "then()")

  (({:okk, _} <~ {:ok, 2} && "OK") || "NOK")
  |> IO.inspect(label: "<~")

  if ok_or({:ok, 1}, 2) == 1 do
    IO.puts("ok_or({:ok, 1}, 2) == 1")
  end

  dcase 1 do
    two when two == 2 -> 2
    3 -> 3
  end
  |> IO.inspect(label: "dcase")
end
