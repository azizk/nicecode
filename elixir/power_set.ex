defmodule PowerSet do
  @vsn 1
  @author "Aziz Köksal"
  @license "MIT"

  @moduledoc """
  A module for generating the "[power set](https://en.wikipedia.org/wiki/Power_set)"
  of a given set or list.

  **Version:** #{@vsn}
  **Author:** #{@author}
  **License:** #{@license}
  """

  @typedoc "A set element may be any `term`."
  @type value :: term

  @typedoc "Constructs a power set type with the given element type `v`."
  @type t(v) :: MapSet.t(MapSet.t(v))

  @typedoc "A power set's type is a set of sets, where `value` is the type of their elements."
  @type t :: t(value)

  @doc """
  Creates a power set from an `enumerable`.

  Returns the result as a `MapSet` of `MapSet`s.

  ## Example

    iex> PowerSet.new([:a, :b])
    #MapSet<[#MapSet<[]>, #MapSet<[:a]>, #MapSet<[:b]>, #MapSet<[:a, :b]>]>

  """
  @spec new(Enum.t()) :: t
  def new(enumerable) do
    [[] | combine(enumerable)] |> MapSet.new(&MapSet.new/1)
  end

  @doc """
  Creates a power set from an `enumerable` via the given `transform` function.

  Returns the result as a `MapSet` of `MapSet`s.

  ## Example

    iex> PowerSet.new([:a, :b], &to_string/1)
    #MapSet<[#MapSet<[]>, #MapSet<["a"]>, #MapSet<["b"]>, #MapSet<["a", "b"]>]>

  """
  @spec new(Enum.t(), (term -> value)) :: t(value)
  def new(enumerable, transform)

  def new(enumerable, transform) when is_function(transform, 1) do
    new(Enum.map(enumerable, transform))
  end

  def new(_enumerable, transform) do
    raise ArgumentError, "expected a 1-arity transform function, got: #{inspect(transform)}"
  end

  @doc """
  Creates a list of combinations from an `enumerable`.

  Does not remove duplicate elements.

  Returns the result as a list of lists.

  ## Example

    iex> PowerSet.combine([:a, :b, :c])
    [[:a], [:a, :c], [:a, :b, :c], [:a, :b], [:b], [:b, :c], [:c]]

  """
  @spec combine(Enum.t()) :: [[value]]
  def combine(enumerable) when is_list(enumerable), do: do_combine(enumerable)
  def combine(enumerable), do: do_combine(Enum.to_list(enumerable))

  @spec do_combine([value]) :: [[value]]
  defp do_combine([]), do: []

  defp do_combine([x | xs]) do
    combinations = do_combine(xs)
    # Simpler to read: `[[x] | Enum.map(combinations, &[x | &1])] ++ combinations`
    [[x] | Enum.reduce(combinations, combinations, &[[x | &1] | &2])]
  end
end
