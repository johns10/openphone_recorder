defmodule OpenphoneRecorder.Chunker.Weekly do
  @behaviour OpenphoneRecorder.Chunker.Behaviour
  alias OpenphoneRecorder.Chunker.Queue
  alias OpenphoneRecorder.Tokens
  alias OpenphoneRecorder.DateSupport

  def chunk_items(queue, opts \\ [])

  def chunk_items(%{queue: queue, done: done}, _) when queue == [],
    do: done

  def chunk_items(%{queue: [head, next | _]} = acc, opts) do
    case split?(head, next, opts) do
      true ->
        acc
        |> Queue.add_to_current()
        |> Queue.shift_queue(1)

      false ->
        acc
        |> Queue.complete_current()
        |> Queue.shift_queue(1)
    end
    |> chunk_items(opts)
  end

  def chunk_items(acc, opts) do
    acc
    |> Queue.complete_current()
    |> Queue.shift_queue(1)
    |> chunk_items(opts)
  end

  def split?(head, next, opts) do
    head_date = DateSupport.range_day(head.summary_interval, opts)
    next_date = DateSupport.range_day(next.summary_interval, opts)

    DateSupport.week(head_date) == DateSupport.week(next_date)
  end

  @impl true
  def prompt_count(_opts) do
    prompt_text("", 100)
    |> Tokens.count()
  end

  @impl true
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
