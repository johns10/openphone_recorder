defmodule Discussit.Init do
  alias Discussit.Repo
  alias Discussit.Summarizers.Summarizer

  def generate_default_summarizers() do
    daily_attrs = %Summarizer{
      name: "daily",
      prompt: ~s[
        Summarize the following conversation, maintaining the key context and important details:
        \"\"\"\<%= context %>\"\"\"
        Be sure to capture any recurring events or topics and provide their respective counts.
        Your summary should be concise yet comprehensive, focusing on the most relevant information.
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
    }

    daily =
      case Repo.get_by(Summarizer, name: "daily") do
        nil ->
          Repo.insert!(daily_attrs)

        summarizer ->
          attrs = Map.from_struct(daily_attrs)

          summarizer
          |> Discussit.Summarizers.change_summarizer(attrs)
          |> Repo.update!()
      end

    weekly_attrs = %Summarizer{
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
      fixed_reduction: 300,
      summarizer_id: daily.id
    }

    case Repo.get_by(Summarizer, name: "weekly") do
      nil ->
        Repo.insert!(weekly_attrs)

      summarizer ->
        attrs = Map.from_struct(weekly_attrs)

        summarizer
        |> Discussit.Summarizers.change_summarizer(attrs)
        |> Repo.update!()
    end

    monthly_attrs = %Summarizer{
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
      fixed_reduction: 800,
      summarizer_id: daily.id
    }

    monthly =
      case Repo.get_by(Summarizer, name: "monthly") do
        nil ->
          Repo.insert!(monthly_attrs)

        summarizer ->
          attrs = Map.from_struct(monthly_attrs)

          summarizer
          |> Discussit.Summarizers.change_summarizer(attrs)
          |> Repo.update!()
      end

    yearly_attrs = %Summarizer{
      name: "yearly",
      prompt: ~s[
        Rewrite the following summary.
        Omit as little information as possible.
        The summary should be about <%= floor(max_output_count * 1.33) %> words long.
        SUMMARY: \"\"\"
        <%= context %>
        \"\"\"
        ],
      reducer_prompt: ~s[
        Rewrite the following summary.
        Omit as little information as possible.
        SUMMARY: \"\"\"
        <%= context %>
          \"\"\"
        ],
      chunker: :yearly,
      fixed_reduction: 300,
      summarizer_id: monthly.id
    }

    case Repo.get_by(Summarizer, name: "yearly") do
      nil ->
        Repo.insert!(yearly_attrs)

      summarizer ->
        attrs = Map.from_struct(yearly_attrs)

        summarizer
        |> Discussit.Summarizers.change_summarizer(attrs)
        |> Repo.update!()
    end
  end
end
