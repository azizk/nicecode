defmodule RomanNumber do
  @vsn 1
  @author "Aziz Köksal"
  @license "MIT"

  @spec to_decimal(String.t()) :: {:ok, pos_integer} | {:error, :invalid}
  def to_decimal(roman_numerals), do: convert(roman_numerals)

  defp convert(s), do: parse(s) |> Enum.reduce({:ok, 0}, &maybe_add/2)

  defp parse(s) do
    case parse_1(s) do
      [] -> [{:error, :invalid}]
      values -> values
    end
  end

  defp parse_1("MMM" <> rest), do: [3000 | parse_2(rest)]
  defp parse_1("MM" <> rest), do: [2000 | parse_2(rest)]
  defp parse_1("M" <> rest), do: [1000 | parse_2(rest)]
  defp parse_1(rest), do: parse_2(rest)

  defp parse_2("CM" <> rest), do: [900 | parse_3(rest)]
  defp parse_2("CD" <> rest), do: [400 | parse_3(rest)]
  defp parse_2("D" <> rest), do: [500 | parse_2_c(rest)]
  defp parse_2(rest), do: parse_2_c(rest)

  defp parse_2_c("CCC" <> rest), do: [300 | parse_3(rest)]
  defp parse_2_c("CC" <> rest), do: [200 | parse_3(rest)]
  defp parse_2_c("C" <> rest), do: [100 | parse_3(rest)]
  defp parse_2_c(rest), do: parse_3(rest)

  defp parse_3("XC" <> rest), do: [90 | parse_4(rest)]
  defp parse_3("XL" <> rest), do: [40 | parse_4(rest)]
  defp parse_3("L" <> rest), do: [50 | parse_3_x(rest)]
  defp parse_3(rest), do: parse_3_x(rest)

  defp parse_3_x("XXX" <> rest), do: [30 | parse_4(rest)]
  defp parse_3_x("XX" <> rest), do: [20 | parse_4(rest)]
  defp parse_3_x("X" <> rest), do: [10 | parse_4(rest)]
  defp parse_3_x(rest), do: parse_4(rest)

  defp parse_4("IX" <> rest), do: [9 | parse_5(rest)]
  defp parse_4("IV" <> rest), do: [4 | parse_5(rest)]
  defp parse_4("V" <> rest), do: [5 | parse_5_i(rest)]
  defp parse_4(rest), do: parse_5_i(rest)

  defp parse_5_i("III" <> rest), do: [3 | parse_5(rest)]
  defp parse_5_i("II" <> rest), do: [2 | parse_5(rest)]
  defp parse_5_i("I" <> rest), do: [1 | parse_5(rest)]
  defp parse_5_i(rest), do: parse_5(rest)

  defp parse_5(""), do: []
  defp parse_5(_), do: [{:error, :invalid}]

  defp maybe_add(a, {:ok, b}) when is_integer(a), do: {:ok, a + b}
  defp maybe_add(error, _), do: error
end
