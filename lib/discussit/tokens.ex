defmodule Discussit.Tokens do
  alias Discussit.Statements.Statement
  alias Discussit.Summaries.Summary

  def max_text_output_count(opts \\ []) do
    percentage_reduction = Keyword.get(opts, :percentage_reduction, nil)
    fixed_reduction = Keyword.get(opts, :fixed_reduction, nil)
    max_token_count = Keyword.get(opts, :max_tokens, 4096)
    prompt_count = Keyword.get(opts, :prompt) |> count()

    case {percentage_reduction, fixed_reduction} do
      {nil, fixed} ->
        fixed

      {percentage_reduction, nil} ->
        ((max_token_count - prompt_count) / (1 / percentage_reduction + 1))
        |> floor()
    end
  end

  def max_text_count(opts \\ []) do
    max_token_count = Keyword.get(opts, :max_tokens, 4096)
    prompt = Keyword.get(opts, :prompt)
    prompt_count = count(prompt)

    max_token_count - prompt_count
  end

  def max_context_count(opts \\ []) do
    max_token_count = Keyword.get(opts, :max_tokens, 4096)
    prompt = Keyword.get(opts, :prompt)
    prompt_count = count(prompt)

    max_token_count - prompt_count - max_text_output_count(opts)
  end

  def count(statements) when is_list(statements),
    do: statements |> Enum.reduce(0, fn statement, acc -> acc + count(statement) end)

  def count([%Statement{} | _] = statements),
    do: Enum.reduce(statements, 0, fn statement, acc -> acc + count(statement) end)

  def count([%Summary{} | _] = statements),
    do: Enum.reduce(statements, 0, fn statement, acc -> acc + count(statement) end)

  def count(%Statement{} = statement), do: statement |> Statement.render_for_prompt() |> count()

  def count(%Summary{} = summary), do: summary |> Summary.render_for_prompt() |> count()

  def count(string), do: Gpt3Tokenizer.token_count(string)
end
