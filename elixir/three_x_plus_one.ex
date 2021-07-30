defmodule TXP1 do
  @moduledoc """
  The `3x+1` match problem.

  See: [The Simplest Math Problem No One Can Solve](https://www.youtube.com/watch?v=094y1Z2wpJg)
  """

  def fun(x, acc \\ []) when x > 0 do
    acc = if acc == [], do: [x], else: acc

    case x do
      x when x in [1, 2, 4] ->
        Enum.reverse(acc)

      x ->
        y = if rem(x, 2) == 0, do: div(x, 2), else: 3 * x + 1
        fun(y, [y | acc])
    end
  end
end
