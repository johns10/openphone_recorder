defmodule Discussit.Usages do
  @moduledoc """
  The Usages context.
  """

  import Ecto.Query, warn: false
  alias Discussit.Repo

  alias Discussit.Usages.Usage

  def sum_usages(opts \\ []) do
    sum_usages_query(opts)
    |> Repo.one()
  end

  def sum_usages_query(opts) do
    filters = Keyword.get(opts, :filters, [])

    Usage
    |> filter_by_account_id(filters[:account_id])
    |> select([u], sum(u.total))
  end

  def list_usages do
    Repo.all(Usage)
  end

  def get_usage!(id), do: Repo.get!(Usage, id)

  defp filter_by_account_id(query, nil), do: query

  defp filter_by_account_id(query, account_id) do
    query
    |> where([u], u.account_id == ^account_id)
  end

  def create_usage(attrs \\ %{}) do
    %Usage{}
    |> Usage.changeset(attrs)
    |> Repo.insert()
  end

  def update_usage(%Usage{} = usage, attrs) do
    usage
    |> Usage.changeset(attrs)
    |> Repo.update()
  end

  def delete_usage(%Usage{} = usage) do
    Repo.delete(usage)
  end

  def change_usage(%Usage{} = usage, attrs \\ %{}) do
    Usage.changeset(usage, attrs)
  end

  def calculate_total(
        %{
          provider: :openai,
          model: "gpt-3.5-turbo",
          meta: %{
            completion_tokens: completion_tokens,
            prompt_tokens: prompt_tokens,
            total_tokens: _
          }
        } = attrs
      ) do
    total = 0.0000015 * prompt_tokens + 0.000002 * completion_tokens
    Map.put(attrs, :total, total)
  end

  def calculate_total(
        %{
          provider: :openai,
          model: _,
          meta: %{
            completion_tokens: completion_tokens,
            prompt_tokens: prompt_tokens,
            total_tokens: _
          }
        } = attrs
      ) do
    total = 0.0000015 * prompt_tokens + 0.000002 * completion_tokens
    Map.put(attrs, :total, total)
  end

  def calculate_total(
        %{
          provider: :openai,
          model: "whisper-1",
          meta: %{
            duration: duration
          }
        } = attrs
      ) do
    total = ceil(duration / 60) * 0.006
    Map.put(attrs, :total, total)
  end

  def calculate_total(
        %{
          provider: :assemblyai,
          model: "assemblyai_default",
          meta: %{
            duration: duration
          }
        } = attrs
      ) do
    total = duration * 0.000181
    Map.put(attrs, :total, total)
  end

  def calculate_total(
        %{
          provider: :discussit,
          model: "BAAI/bge-large-en-v1.5",
          meta: %{
            tokens: tokens
          }
        } = attrs
      ) do
    total = tokens * 0.0000001
    Map.put(attrs, :total, total)
  end
end
