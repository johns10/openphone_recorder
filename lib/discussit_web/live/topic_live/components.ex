defmodule DiscussitWeb.TopicLive.Components do
  alias Discussit.Models.Model
  alias Phoenix.LiveView.JS
  alias Discussit.Topics.Topic
  import DiscussitWeb.CoreComponents
  use Phoenix.Component

  use Phoenix.VerifiedRoutes,
    endpoint: DiscussitWeb.Endpoint,
    router: DiscussitWeb.Router

  attr(:topic, Topic, required: true)
  attr(:show_actions, :boolean, default: true)
  attr(:summarizer_status, :atom, default: :not_started)

  def show_topic_card(assigns) do
    ~H"""
    <div class="card bg-base-300 rounded-box w-full">
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

  attr(:topic, Topic, required: true)
  attr(:to_model, Model)
  attr(:mode, :atom, default: :index)
  attr(:id, :string, required: true)

  def topic_card(%{mode: :index} = assigns) do
    ~H"""
    <div id={@id} class="card bg-base-200 shadow-xl w-full">
      <div class="card-body">
        <div class="flex flex-row items-center justify-between">
          <h2 class="card-title line-clamp-2">
            <%= @topic.title || @topic.model_title %>
          </h2>
          <.icon :if={!@topic.title} name="hero-question-mark-circle" class="bg-warning " />
          <.icon :if={@topic.title} name="hero-check-circle" class="bg-success" />
        </div>
        <p class="line-clamp-6"><%= @topic.description || @topic.model_description %></p>
        <.keyword_badges topic={@topic} />
        <div class="card-actions">
          <.link class="btn btn-sm btn-outline my-0" patch={~p"/topics/#{@topic}"}>
            <.icon name="hero-magnifying-glass" class="w-5 h-5" /> Show
          </.link>
          <.link
            class="btn btn-sm btn-outline my-0"
            phx-click="summarize-topic"
            phx-value-topic-id={@topic.id}
          >
            <.icon
              :if={@topic.summarizer_status == :not_started}
              name="hero-document-text"
              class="w-5 h-5"
            />
            <span
              :if={@topic.summarizer_status != :not_started}
              class="loading loading-spinner loading-xs"
            >
            </span>
            Summarize
          </.link>
          <.link
            class="btn btn-sm btn-outline my-0"
            phx-click="confirm-topic"
            phx-value-topic-id={@topic.id}
          >
            <.icon name="hero-check" class="w-5 h-5" /> Confirm
          </.link>
        </div>
      </div>
    </div>
    """
  end

  def topic_card(%{mode: :migrate} = assigns) do
    ~H"""
    <div id={@id} class="card bg-base-200 shadow-xl w-full">
      <div class="card-body">
        <div class="flex flex-row">
          <h2 class="card-title line-clamp-2">
            <%= @topic.title || @topic.model_title %>
          </h2>
        </div>
        <p class="line-clamp-6"><%= @topic.description || @topic.model_description %></p>
        <.keyword_badges topic={@topic} />
        <div class="card-actions justify-between">
          <div class="flex gap-x-2">
            <.link
              class="btn btn-square btn-sm btn-outline my-0"
              patch={~p"/topics/#{@topic}/show/migrate/#{@to_model}"}
            >
              <.icon name="hero-arrows-right-left" class="w-5 h-5" />
            </.link>
            <.link
              class="btn btn-square btn-sm btn-outline my-0"
              phx-click="summarize-topic"
              phx-value-topic-id={@topic.id}
            >
              <.icon
                :if={@topic.summarizer_status == :not_started}
                name="hero-document-text"
                class="w-5 h-5"
              />
              <span
                :if={@topic.summarizer_status != :not_started}
                class="loading loading-spinner loading-xs"
              >
              </span>
            </.link>
          </div>
        </div>
      </div>
    </div>
    """
  end

  attr(:topic, Topic, required: true)

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
      <:item title="Keywords">
        <.keyword_badges topic={@topic} />
      </:item>
      <:item title="Sentiment"><%= @topic.sentiment %></:item>
    </.list>
    """
  end
end
