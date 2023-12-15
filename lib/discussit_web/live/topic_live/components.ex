defmodule DiscussitWeb.TopicLive.Components do
  alias Phoenix.LiveView.JS
  import DiscussitWeb.CoreComponents
  use Phoenix.Component

  use Phoenix.VerifiedRoutes,
    endpoint: DiscussitWeb.Endpoint,
    router: DiscussitWeb.Router

  attr(:topic, Discussit.Topics.Topic, required: true)
  attr(:show_actions, :boolean, default: true)

  def topic_card(assigns) do
    ~H"""
    <div class="card bg-base-300 rounded-box w-3/4">
      <div class="card-body">
        <.header class="card-title">
          Topic
          <:subtitle>This is a topic record from your database.</:subtitle>
          <:actions :if={@show_actions}>
            <div class="flex items-center space-x-2">
              <.link
                phx-click="summarize-topic"
                phx-value-topic-id={@topic.id}
                class={[
                  "btn",
                  if(@summarizer_status == :not_started, do: "btn-primary", else: "btn-disabled")
                ]}
              >
                <span
                  :if={@summarizer_status != :not_started}
                  class="loading loading-spinner loading-xs"
                /> Summarize topic
              </.link>
              <.link
                class="btn btn-primary"
                patch={~p"/topics/#{@topic}/show/edit"}
                phx-click={JS.push_focus()}
              >
                Edit topic
              </.link>
              <.link class="btn btn-primary" phx-click="confirm-topic" phx-value-topic-id={@topic.id}>
                Confirm topic
              </.link>
            </div>
          </:actions>
        </.header>
        <.topic_list topic={@topic} />
      </div>
    </div>
    """
  end

  attr(:topic, Discussit.Topics.Topic, required: true)

  def topic_list(assigns) do
    ~H"""
    <.list>
      <:item title="Title">
        <.icon :if={!@topic.title} name="hero-question-mark-circle" class="bg-warning " />
        <.icon :if={@topic.title} name="hero-check-circle" class="bg-success" />
        <%= @topic.title || @topic.model_title %>
      </:item>
      <:item title="Description">
        <.icon :if={!@topic.description} name="hero-question-mark-circle" class="bg-warning" />
        <.icon :if={@topic.description} name="hero-check-circle" class="bg-success" />
        <%= @topic.description || @topic.model_description %>
      </:item>
      <:item title="Sentiment"><%= @topic.sentiment %></:item>
    </.list>
    """
  end
end
