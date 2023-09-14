defmodule ListSwapper do
  @vsn 1
  @author "Aziz Köksal"
  @license "MIT"

  @moduledoc """
  Swaps two adjacent items at the given index.

  **Version:** #{@vsn}
  **Author:** #{@author}
  **License:** #{@license}
  """

  # With `Enum.split/2`
  def swap_at_slow(list, index) when is_list(list) and index >= 0 do
    case Enum.split(list, index) do
      {head, [a, b | rest]} -> head ++ [b, a | rest]
      _ -> list
    end
  end

  # With `Enum.reduce/3`
  def swap_at_slow1(list, index) when is_list(list) and index >= 0 do
    Enum.reduce_while(list, {[], 0, list}, fn
      _item, {_, _, [_]} ->
        {:halt, list}

      item, {[prev | acc], i, [_ | rest]} when i > index ->
        {:halt, :lists.reverse([prev, item | acc], rest)}

      item, {acc, i, [_ | rest]} ->
        {:cont, {[item | acc], i + 1, rest}}
    end)
  end

  # With functions
  def swap_at(list, index) when is_list(list) and index >= 0,
    do: do_swap(list, [], 0, index, list)

  defp do_swap([a, b | rest], acc, index, index, _), do: :lists.reverse([a, b | acc], rest)

  defp do_swap([], _acc, _i, _index, original), do: original

  defp do_swap([item | rest], acc, i, index, original),
    do: do_swap(rest, [item | acc], i + 1, index, original)
end
