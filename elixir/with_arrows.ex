defmodule WithArrows do
  @vsn 1
  @author "Aziz Köksal"
  @license "MIT"

  @moduledoc """
  A macro statement with arrow clauses inside the do-body.

  **Version:** #{@vsn}
  **Author:** #{@author}
  **License:** #{@license}
  """

  defmacro with_arrows(do: do_block, else: else_block) do
    {:__block__, [], [_condition | _rest] = statements} = do_block
    {last_statement, conditions} = List.pop_at(statements, -1)

    quote do
      with unquote(conditions) do
        unquote(last_statement)
      else
        unquote(else_block)
      end
    end
  end

  _ =
    quote do
      with true <- x, false <- y do
        {x, y}
      else
        b -> b
      end
    end ==
      {:with, [],
       [
         {:<-, [], [true, {:x, [if_undefined: :apply], Elixir}]},
         {:<-, [], [false, {:y, [if_undefined: :apply], Elixir}]},
         [
           do: {{:x, [if_undefined: :apply], Elixir}, {:y, [if_undefined: :apply], Elixir}},
           else: [
             {:->, [],
              [
                [{:b, [if_undefined: :apply], Elixir}],
                {:b, [if_undefined: :apply], Elixir}
              ]}
           ]
         ]
       ]}

  def test() do
    with_arrows do
      true <- File.exists?("file.txt")
      :ok <- File.touch("file.txt")

      File.read("file.txt")
    else
      false -> :file_missing
      {:error, error} -> error
    end
  end
end
