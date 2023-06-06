defmodule OpenphoneRecorder.Statements.Chunker.Temporal do
  alias OpenphoneRecorder.Tokens

  def prompt_fun(text, opts) do
    max_text_output = Tokens.max_text_output_count(opts)

    """
    First, give the following text an informative title.

    Second, write a summary of the following conversation.
    Remove any irrelevant information and filler words.
    The summary should be no longer than #{max_text_output} words.

    Return your answer in the following format:
    Title | Summary
    For Example:
    Why Artificial Intelligence is Good | AI can make humans more productive by automating many repetitive processes.

    TITLE AND SUMMARY:
    \"\"\"#{text}\"\"\"
    """
  end
end
