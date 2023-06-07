defmodule OpenphoneRecorder.Tokens do
  alias OpenphoneRecorder.Statements.Statement
  alias OpenphoneRecorder.Statements.Chunker

  def max_text_output_count(opts \\ []) do
    max_token_count = Keyword.get(opts, :max_tokens, 4096)
    chunk_style = Keyword.get(opts, :chunk_style, :temporal)
    prompt_count = Chunker.prompt_count(chunk_style, opts)
    percentage_reduction = Keyword.get(opts, :percentage_reduction, 0.25)

    ((max_token_count - prompt_count) / (1 / percentage_reduction + 1))
    |> floor()
  end

  def max_text_count(opts \\ []) do
    max_token_count = Keyword.get(opts, :max_tokens, 4096)
    chunk_style = Keyword.get(opts, :chunk_style, :temporal)
    prompt_count = Chunker.prompt_count(chunk_style, opts)

    max_token_count - prompt_count
  end

  def count(statements) when is_list(statements),
    do: statements |> Enum.reduce(0, fn statement, acc -> acc + count(statement) end)

  def count(%Statement{} = statement), do: statement |> Statement.render_for_prompt() |> count()

  def count(string) do
    string
    |> String.split(~r{(\\n|[^\w'])+})
    |> Enum.filter(fn x -> x != "" end)
    |> Enum.count()
  end
end
