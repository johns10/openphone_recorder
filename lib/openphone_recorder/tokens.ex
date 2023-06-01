defmodule OpenphoneRecorder.Tokens do
  alias OpenphoneRecorder.Statements.Statement

  def max_text_count(opts \\ []) do
    max_token_count = Keyword.get(opts, :max_tokens, 4096)
    margin = Keyword.get(opts, :margin, 0)
    prompt_fun = Keyword.fetch!(opts, :prompt_fun)
    prompt = prompt_fun.("")
    prompt_count = count(prompt)

    max_token_count - prompt_count - margin
  end

  def count(statements) when is_list(statements),
    do: statements |> Enum.reduce(0, fn statement, acc -> acc + count(statement) end)

  def count(%Statement{content: content}), do: count(content)

  def count(string) do
    string
    |> String.split(~r{(\\n|[^\w'])+})
    |> Enum.filter(fn x -> x != "" end)
    |> Enum.count()
  end
end
