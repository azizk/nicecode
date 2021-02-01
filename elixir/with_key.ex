defmodule WithKey do
  # Author: Aziz Köksal
  # License: MIT

  @moduledoc """
  The `w_key` macro is similar to the `with` macro,
  but it enables you to assign an atom key to each `<-` clause
  to make them easily distinguishable in the `else` body.

  Using the standard `with` macro creates syntax noise
  and makes the code less readable when you want
  to be able to tell which clause failed. For comparison:

      with {_, 1} <- {:fst, 1},
           {_, 2} <- {:snd, 3} do
        :ok
      else
        {:fst, _} -> {:error, :first}
        {:snd, _} -> {:error, :second}
      end

  # Examples

      defmodule WK do
        import WithKey

        def test do
          w_key fst: 1 <- 1,
                snd: 2 <- 3 do
            :ok
          else
            fst: _ -> {:error, :first}
            snd: _ -> {:error, :second}
          end
        end
      end

      iex(1)> WK.test()
      :ok

      iex(1)> w_key x: :y <- :y do
      ...(1)>   :z
      ...(1)> end
      :z
  """

  @spec w_key(Macro.t(), Macro.t()) :: Macro.t()
  defmacro w_key(clauses, body) do
    if not match?([{key, {:<-, _, _}} | _] when is_atom(key), clauses) do
      raise CompileError,
        file: __CALLER__.file,
        line: __CALLER__.line,
        description: "expected keyword clauses in the form of `w_key key: _ <- _ do ... end`"
    end

    clauses =
      Enum.map(clauses, fn
        {key_tag, {:<-, meta, [{:when, w_meta, [w_lhs, w_rhs]}, rhs]}} ->
          lhs = {:when, w_meta, [[{{:_, [], Elixir}, w_lhs}], w_rhs]}
          {:<-, meta, [lhs, [{key_tag, rhs}]]}

        {key_tag, {:<-, meta, [lhs, rhs]}} ->
          {:<-, meta, [[{{:_, [], Elixir}, lhs}], [{key_tag, rhs}]]}
      end)

    body =
      if else_body = body[:else] do
        put_in(
          body[:else],
          Enum.map(else_body, fn
            {:->, meta, [[[{key_tag, {:when, w_meta, [w_lhs, w_rhs]}}]], rhs]} ->
              {:->, meta, [[{:when, w_meta, [[{key_tag, w_lhs}], w_rhs]}], rhs]}

            no_when ->
              no_when
          end)
        )
      else
        body
      end

    {:with, [line: __CALLER__.line], clauses ++ [body]}
  end

  defmacro w_key do
    raise CompileError, description: "can't use w_key without `<-` clauses and a `do end` body"
  end

  defmacro w_key(_) do
    quote do: w_key()
  end
end
