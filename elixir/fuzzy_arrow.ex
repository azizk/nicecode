defmodule FuzzyArrow do
  @vsn 1
  @author "Aziz Köksal"
  @license "MIT"

  @moduledoc """
  An operator macro that `nil`ifies variables
  when the right-hand side doesn't exactly match the left-hand side.

  TODO: allow partial matches and only nilify non-matching parts.

  **Version:** #{@vsn}
  **Author:** #{@author}
  **License:** #{@license}
  """

  defmacro lhs <~ rhs do
    lhs_without_when =
      case lhs do
        {:when, _, [lhs, _rhs]} -> lhs
        _ -> lhs
      end

    nilified =
      Macro.prewalk(lhs_without_when, fn
        {var, _meta, context} when is_atom(var) and is_atom(context) -> nil
        other -> other
      end)

    quote do
      unquote(lhs_without_when) =
        case unquote(rhs) do
          unquote(lhs) -> unquote(lhs_without_when)
          _ -> unquote(nilified)
        end
    end
  end
end

defmodule FuzzyArrowTest do
  import ExUnit.Assertions
  import FuzzyArrow

  ({:ok, %{x: x}} when x > 0) <~ {:ok, %{x: 1, y: 2}}
  assert x == 1

  [a, b, c] <~ []
  assert a == nil and b == nil and c == nil

  [1, b, 3] <~ [4, 5, 6]
  assert b == nil
end
