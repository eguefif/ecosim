defmodule Ecosim.Sim.Market.ActorsFile do
  @moduledoc """
  Reads and writes the market's actors file: a CSV file with one actor per line.

      role,name,wt
      buyer,Alice,102
      seller,David,98

  - `role` is `buyer` or `seller`. The French `acheteur` and `vendeur` are also
    accepted when reading, case-insensitive.
  - `name` is the actor's name. It must be unique and cannot contain a comma.
  - `wt` is the actor's willingness to pay (buyer) or to accept (seller).

  The header line is written by `encode/1` and optional when reading. Blank lines
  are ignored.
  """

  alias Ecosim.Sim.Market.Actor

  @header "role,name,wt"

  @type actors() :: %{buyers: [Actor.t()], sellers: [Actor.t()]}

  @type error() ::
          :empty
          | :no_buyers
          | :no_sellers
          | {:duplicate_name, String.t()}
          | {:invalid_line, pos_integer()}
          | {:invalid_role, pos_integer()}
          | {:invalid_name, pos_integer()}
          | {:invalid_wt, pos_integer()}

  @doc """
  Build the file content from `actors`, buyers first.
  """
  @spec encode([Actor.t()]) :: String.t()
  def encode(actors) when is_list(actors) do
    lines =
      actors
      |> Enum.sort_by(&if(&1.type == :buyer, do: 0, else: 1))
      |> Enum.map(fn %Actor{type: type, name: name, wt: wt} ->
        Enum.join([Atom.to_string(type), name, format_wt(wt)], ",")
      end)

    Enum.join([@header | lines], "\n") <> "\n"
  end

  @doc """
  Parse a file `content` into buyers and sellers.

  Line numbers in errors start at 1 and count the header and blank lines, so
  they match what the user sees in their editor.
  """
  @spec decode(String.t()) :: {:ok, actors()} | {:error, error()}
  def decode(content) when is_binary(content) do
    content
    |> String.replace_prefix("﻿", "")
    |> String.split(~r/\R/)
    |> Enum.with_index(1)
    |> Enum.reject(fn {line, _} -> String.trim(line) == "" end)
    |> drop_header()
    |> parse_lines([])
    |> validate()
  end

  defp drop_header([{line, _} | rest] = lines) do
    first_field = line |> String.split(",") |> hd() |> String.trim() |> String.downcase()
    if first_field in ["role", "rôle"], do: rest, else: lines
  end

  defp drop_header([]), do: []

  defp parse_lines([], acc), do: {:ok, Enum.reverse(acc)}

  defp parse_lines([{line, number} | rest], acc) do
    case parse_line(line, number) do
      {:ok, actor} -> parse_lines(rest, [actor | acc])
      {:error, _} = error -> error
    end
  end

  defp parse_line(line, number) do
    with [role, name, wt] <- line |> String.split(",") |> Enum.map(&String.trim/1),
         {:role, type} when not is_nil(type) <- {:role, Actor.type_string_to_atom(role)},
         {:name, name} when name != "" <- {:name, name},
         {:wt, {wt, ""}} <- {:wt, Float.parse(wt)} do
      {:ok, Actor.new(type, name, normalize_wt(wt))}
    else
      fields when is_list(fields) -> {:error, {:invalid_line, number}}
      {:role, _} -> {:error, {:invalid_role, number}}
      {:name, _} -> {:error, {:invalid_name, number}}
      {:wt, _} -> {:error, {:invalid_wt, number}}
    end
  end

  defp validate({:error, _} = error), do: error
  defp validate({:ok, []}), do: {:error, :empty}

  defp validate({:ok, actors}) do
    {buyers, sellers} = Enum.split_with(actors, &(&1.type == :buyer))

    cond do
      duplicate = duplicate_name(actors) -> {:error, {:duplicate_name, duplicate}}
      buyers == [] -> {:error, :no_buyers}
      sellers == [] -> {:error, :no_sellers}
      true -> {:ok, %{buyers: buyers, sellers: sellers}}
    end
  end

  defp duplicate_name(actors) do
    actors
    |> Enum.map(& &1.name)
    |> Enum.frequencies()
    |> Enum.find_value(fn {name, count} -> if count > 1, do: name end)
  end

  # Keep whole numbers as integers so "102" stays 102, not 102.0.
  defp normalize_wt(wt) when wt == trunc(wt), do: trunc(wt)
  defp normalize_wt(wt), do: wt

  defp format_wt(wt) when is_integer(wt), do: Integer.to_string(wt)
  defp format_wt(wt) when is_float(wt), do: wt |> normalize_wt() |> to_string()
end
