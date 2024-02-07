defmodule Discussit.SummarizersFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Discussit.Summarizers` context.
  """

  @doc """
  Generate a summarizer.
  """
  def daily_summarizer_fixture(),
    do:
      summarizer_fixture(%{
        name: "daily",
        prompt: ~s[
          Summarize the following conversation, maintaining the key context and important details:
          \"\"\"\<%= context %>\"\"\"
          Be sure to capture any recurring events or topics and provide their respective counts.
          Your summary should be concise yet comprehensive, focusing on the most relevant information.
          Summarize the content to approximately <%= percentage_reduction * 100 %>% of its original length.
        ],
        reducer_prompt: ~s[
          <%= if previous_summary == "" do %>
          The text data for this segment exceeds the context window.
          Start a summary of the following segment of the conversation, maintaining the key context and important details
          Assume the conversation will continue.
          CONVERSATION: \"\"\"
          <%= context %>
          \"\"\"
          Be sure to capture any recurring events or topics and provide their respective counts.
          Your summary should be concise yet comprehensive, focusing on the most relevant information within the given segment.
          <% else %>
          The text data for this segment exceeds the context window.
          Summarize the following segment of the conversation, maintaining the key context and important details:
          \"\"\"
          <%= context %>
          \"\"\"
          Be sure to capture any recurring events or topics and provide their respective counts.
          Your summary should be concise yet comprehensive, focusing on the most relevant information within the given segment.
          Continue the previous summary:
          <%= previous_summary %>
          <% end %>
        ],
        percentage_reduction: 0.25,
        chunker: :daily
      })

  def weekly_summarizer_fixture(),
    do:
      summarizer_fixture(%{
        name: "weekly",
        prompt: ~s[
          Summarize the daily summaries from the past week to create a weekly summary.
          Summarize the content to approximately <%= floor(max_output_count * 1.33) %> words.
          SUMMARY: \"\"\"
          <%= context %>
          \"\"\"
          Your summary should be concise yet comprehensive, focusing on the most relevant information.
        ],
        reducer_prompt: ~s[
          <%= if previous_summary == "" do %>
          The text data for this segment exceeds the context window.
          Start a summary of the daily summaries from the past week to create a weekly summary.
          Assume the conversation will continue.
          CONVERSATION: \"\"\"
          <%= context %>
          \"\"\"
          Be sure to capture any recurring events or topics and provide their respective counts.
          Your summary should be concise yet comprehensive, focusing on the most relevant information within the given segment.
          <% else %>
          The text data for this segment exceeds the context window.
          Summarize the following segment of the daily summaries from the past week to create a weekly summary.
          \"\"\"
          <%= context %>
          \"\"\"
          Be sure to capture any recurring events or topics and provide their respective counts.
          Your summary should be concise yet comprehensive, focusing on the most relevant information within the given segment.
          Continue the previous summary:
          <%= previous_summary %>
          <% end %>
        ],
        chunker: :weekly,
        fixed_reduction: 300
      })

  def monthly_summarizer_fixture(),
    do:
      summarizer_fixture(%{
        name: "monthly",
        prompt: ~s[
          Generate a summary of the daily summaries from the last month to create a monthly summary.
          Summarize the content to approximately <%= floor(max_output_count * 1.33) %> words.
          SUMMARY: \"\"\"
          <%= context %>
          \"\"\"
          Your summary should be concise yet comprehensive, focusing on the most relevant information.
        ],
        reducer_prompt: ~s[
          <%= if previous_summary == "" do %>
          The text data for this segment exceeds the context window.
          Start a summary of the daily summaries from the past month to create a monthly summary.
          Assume the conversation will continue.
          CONVERSATION: \"\"\"
          <%= context %>
          \"\"\"
          Be sure to capture any recurring events or topics and provide their respective counts.
          Your summary should be concise yet comprehensive, focusing on the most relevant information within the given segment.
          <% else %>
          The text data for this segment exceeds the context window.
          Summarize the following segment of the daily summaries from the past month to create a monthly summary.
          \"\"\"
          <%= context %>
          \"\"\"
          Be sure to capture any recurring events or topics and provide their respective counts.
          Your summary should be concise yet comprehensive, focusing on the most relevant information within the given segment.
          Continue the previous summary:
          <%= previous_summary %>
          <% end %>
        ],
        chunker: :monthly,
        fixed_reduction: 800
      })

  def yearly_summarizer_fixture(),
    do:
      summarizer_fixture(%{
        name: "yearly",
        prompt: ~s[
          Summarize the following summary.
          Omit as little information as possible.
          SUMMARY: \"\"\"
          <%= context %>
          \"\"\"
        ],
        reducer_prompt: ~s[
          Summarize the following summary.
          Omit as little information as possible.
          SUMMARY: \"\"\"
          <%= context %>
          \"\"\"
        ],
        chunker: :monthly,
        fixed_reduction: 300
      })

  def summarizer_fixture(attrs \\ %{}) do
    {:ok, summarizer} =
      attrs
      |> Enum.into(%{
        name: "some name",
        prompt: "some prompt",
        chunker: :daily
      })
      |> Discussit.Summarizers.create_summarizer()

    summarizer
  end
end
