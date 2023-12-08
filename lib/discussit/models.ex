defmodule Discussit.Models do
  @moduledoc """
  The Models context.
  """

  import Ecto.Query, warn: false
  alias Discussit.Repo

  alias Discussit.Models.Model

  def list_models(opts \\ []) do
    order_by = Keyword.get(opts, :order_by, [])
    filters = Keyword.get(opts, :filters, [])

    Model
    |> filter_by_account_id(filters[:account_id])
    |> order_by_inserted_at(order_by[:inserted_at])
    |> maybe_limit(opts[:limit])
    |> Repo.all()
  end

  def get_model!(id), do: Repo.get!(Model, id)

  def create_model(attrs \\ %{}) do
    id = Map.get(attrs, :id, Ecto.UUID.generate())

    with {:ok, _} <- create_object(model_name(id)),
         {:ok, _} <- create_object(merge_model_name(id)) do
      %Model{id: id, merge_object: merge_model_name(id), model_object: model_name(id)}
      |> Model.changeset(attrs)
      |> Repo.insert()
    end
  end

  def update_model(%Model{} = model, attrs) do
    model
    |> Model.changeset(attrs)
    |> Repo.update()
  end

  def delete_model(%Model{id: id} = model) do
    with {:ok, _} <- delete_object(model_name(id)),
         {:ok, _} <- delete_object(merge_model_name(id)) do
      Repo.delete(model)
    end
  end

  def change_model(%Model{} = model, attrs \\ %{}) do
    Model.changeset(model, attrs)
  end

  def get_model_urls(id, method) do
    case Repo.get!(Model, id) do
      nil ->
        nil

      %Model{merge_object: merge_object, model_object: model_object} ->
        with {:ok, model_url} <- presigned_url(model_object, method),
             {:ok, merge_url} <- presigned_url(merge_object, method) do
          {:ok,
           %{
             model_url: model_url,
             merge_url: merge_url
           }}
        end
    end
  end

  def reset_model(%Discussit.Accounts.Account{id: account_id}) do
    [_latest | rest] =
      Discussit.Models.list_models(
        order_by: [inserted_at: :desc],
        filters: [account_id: account_id]
      )

    rest
    |> Enum.each(&delete_model/1)
  end

  defp filter_by_account_id(query, nil), do: query
  defp filter_by_account_id(query, account_id), do: where(query, [t], t.account_id == ^account_id)

  defp order_by_inserted_at(query, nil), do: query
  defp order_by_inserted_at(query, :desc), do: order_by(query, [s], desc: s.inserted_at)
  defp order_by_inserted_at(query, :asc), do: order_by(query, [s], asc: s.inserted_at)

  defp maybe_limit(query, nil), do: query
  defp maybe_limit(query, limit), do: limit(query, [s], ^limit)

  defp model_name(id), do: "#{id}-model"
  defp merge_model_name(id), do: "#{id}-merge-model"

  defp create_object(object) do
    bucket = Application.get_env(:discussit, :bucket)

    ExAws.S3.put_object(bucket, object, "")
    |> ExAws.request()
  end

  def delete_object(object) do
    bucket = Application.get_env(:discussit, :bucket)

    ExAws.S3.delete_object(bucket, object)
    |> ExAws.request()
  end

  defp presigned_url(object, method) do
    bucket = Application.get_env(:discussit, :bucket)

    ExAws.Config.new(:s3)
    |> ExAws.S3.presigned_url(method, bucket, object)
  end
end
