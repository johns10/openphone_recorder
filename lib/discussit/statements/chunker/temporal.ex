defmodule Discussit.Statements.Chunker.Temporal do
  alias Discussit.Tokens

  def prompt_count(_opts) do
    prompt_text("", 100)
    |> Tokens.count()
  end

  def prompt(text, opts) do
    max_text_output = Tokens.max_text_output_count(opts)
    prompt_text(text, max_text_output)
  end

  defp prompt_text(text, max_text_output) do
    """
    First, give the following text an informative title.

    Second, write a summary of the following conversation.
    Remove any irrelevant information and filler words.
    The summary should be no longer than #{max_text_output} words.
    \"\"\"#{text}\"\"\"

    Return your answer in the following format:
    Title | Summary
    e.g
    Why Artificial Intelligence is Good | AI can make humans more productive by automating many repetitive processes.
    Home Hygeine is important | Keeping a clean and tidy home can improve your health by reducing the dust particles you breathe, and reducing your exposure to harmful bacteria.

    TITLE AND SUMMARY:
    """
  end
end
