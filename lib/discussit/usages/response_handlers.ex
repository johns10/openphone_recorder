defmodule Discussit.Usages.ResponseHandlers do
  def chat_completion({:ok, response}), do: chat_completion(response)
  def chat_completion({:error, _} = response), do: response

  def chat_completion(%{usage: usage}, opts) do
    %{
      meta: usage,
      model: Keyword.fetch!(opts, :model),
      product: :chat_completions,
      provider: :openai,
      account_id: Keyword.fetch!(opts, :account_id)
    }
    |> Discussit.Usages.calculate_total()
    |> Discussit.Usages.create_usage()
    |> case do
      {:error, changeset} -> {:ok, usage_error(changeset)}
      other -> other
    end
  end

  def usage_error(changeset) do
    Logger.error("#{__ENV__} Failed to create completion usage", changeset: changeset)
    {:error, changeset}
  end
end
