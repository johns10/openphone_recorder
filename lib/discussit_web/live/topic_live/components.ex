defmodule DiscussitWeb.TopicLive.Components do
  import DiscussitWeb.CoreComponents
  use Phoenix.Component

  use Phoenix.VerifiedRoutes,
    endpoint: DiscussitWeb.Endpoint,
    router: DiscussitWeb.Router

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
