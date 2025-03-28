defmodule Utils do
  @vsn 1
  @author "Aziz Köksal"
  @license "MIT"

  @moduledoc """
  A collection of utility functions and macros.

  **Version:** #{@vsn}
  **Author:** #{@author}
  **License:** #{@license}
  """

  @doc "Returns the unwrapped value if it's an `:ok`-tuple, otherwise `nil`."
  def unwrap({:ok, value}), do: value
  def unwrap({:error, _}), do: nil

  @doc "Returns `{:ok, value}` if it's not `nil`, otherwise `{:error, nil}`."
  def wrap(nil), do: {:error, nil}
  def wrap(value), do: {:ok, value}

  {_block, _meta, check_type_macros} =
    quote do
      # NB: functions are spelled out here to aid discoverability.
      defmacro atom_or(value, default)
      defmacro binary_or(value, default)
      defmacro bitstring_or(value, default)
      defmacro boolean_or(value, default)
      defmacro exception_or(value, default)
      defmacro float_or(value, default)
      defmacro function_or(value, default)
      defmacro integer_or(value, default)
      defmacro list_or(value, default)
      defmacro map_or(value, default)
      defmacro nil_or(value, default)
      defmacro number_or(value, default)
      defmacro pid_or(value, default)
      defmacro port_or(value, default)
      defmacro reference_or(value, default)
      defmacro struct_or(value, default)
      defmacro tuple_or(value, default)

      defmacro unwrap_atom_or(value, default)
      defmacro unwrap_binary_or(value, default)
      defmacro unwrap_bitstring_or(value, default)
      defmacro unwrap_boolean_or(value, default)
      defmacro unwrap_exception_or(value, default)
      defmacro unwrap_float_or(value, default)
      defmacro unwrap_function_or(value, default)
      defmacro unwrap_integer_or(value, default)
      defmacro unwrap_list_or(value, default)
      defmacro unwrap_map_or(value, default)
      defmacro unwrap_nil_or(value, default)
      defmacro unwrap_number_or(value, default)
      defmacro unwrap_pid_or(value, default)
      defmacro unwrap_port_or(value, default)
      defmacro unwrap_reference_or(value, default)
      defmacro unwrap_struct_or(value, default)
      defmacro unwrap_tuple_or(value, default)
    end

  for {:defmacro, _meta1, [{func_name, _meta2, _args}]} <- check_type_macros do
    if not match?("unwrap_" <> _, "#{func_name}") do
      type = String.slice("#{func_name}", 0..-4//1)
      @doc "Returns `value` if it is of type `#{type}`, otherwise `default`. "
      defmacro unquote(func_name)(value, default) do
        is_type = unquote(:"is_#{type}")

        quote do
          value = unquote(value)
          if unquote(is_type)(value), do: value, else: unquote(default)
        end
      end
    else
      type = String.slice("#{func_name}", 7..-4//1)
      @doc "Returns the unwrapped value if it's of type `#{type}`, otherwise `default`. "
      defmacro unquote(func_name)(wrapped, default) do
        is_type = unquote(:"is_#{type}")

        quote do
          case unquote(wrapped) do
            {:ok, value} when unquote(is_type)(value) -> value
            {:ok, _} -> unquote(default)
            {:error, _} -> unquote(default)
          end
        end
      end
    end
  end
end
