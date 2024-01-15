defmodule DiscussitWeb.TopicLive.Components do
  alias Discussit.Models.Model
  alias Phoenix.LiveView.JS
  alias Discussit.Topics.Topic
  alias Discussit.Topics.Keywords
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
            patch={~p"/topics/#{@topic}/edit"}
            id={"edit-topic-#{@topic.id}"}
          >
            <.icon name="hero-pencil" class="w-5 h-5" /> Edit
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
        <div class="flex flex-row justify-between items-center">
          <h2 class="card-title line-clamp-2">
            <%= @topic.title || @topic.model_title %>
          </h2>
          <%= case migration_status(@topic) do %>
            <% :migrated -> %>
              <span class="text-success"><%= score(@topic) %>%</span>
            <% nil -> %>
              <.icon name="hero-x-mark-solid" class="w-5 h-5 bg-error" />
          <% end %>
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

  attr(:tab, :atom, required: true)
  attr(:last_model, Model, required: false, default: nil)
  attr(:latest_model, Model, required: false)

  def topics_header(assigns) do
    ~H"""
    <div class="flex flex-row w-full bg-base-300 items-center justify-between py-2 px-4 sticky top-0 z-10">
      <div class="flex flex-row items-center gap-x-8">
        Topics
        <div role="tablist" class="tabs tabs-bordered">
          <.link
            navigate={~p"/topics?tab=index"}
            role="tab"
            class={["tab", if(@tab == :index, do: "tab-active")]}
          >
            Index
          </.link>
          <.link
            :if={@last_model}
            navigate={~p"/topics/?#{[model_id: @last_model.id]}&tab=migrate"}
            role="tab"
            class={["tab", if(@tab == :migrate, do: "tab-active")]}
          >
            Migrate
          </.link>
          <.link
            role="tab"
            class={["tab", if(@tab == :hierarchy, do: "tab-active")]}
            navigate={~p"/topics/hierarchy"}
          >
            Hierarchy
          </.link>
        </div>
      </div>
      <div>
        <.link
          :if={@latest_model}
          class="btn btn-sm"
          phx-click="regenerate-labels"
          data-confirm="Are you sure? Regenerating topics will relabel all your existing topics."
        >
          Relabel
        </.link>

        <.link class="btn btn-sm" patch={~p"/topics/train"} phx-click={JS.push_focus()}>
          Train
        </.link>

        <.link
          :if={@latest_model}
          class="btn btn-sm"
          phx-click="reset-model"
          data-confirm="This action will delete all automatically generated topics that haven't been used in your conversations."
        >
          Reset
        </.link>
      </div>
    </div>
    """
  end

  attr(:topic, Topic, required: true)
  attr(:index, :integer, required: false, default: nil)
  attr(:count, :integer, required: false, default: nil)

  def topic_outline(assigns) do
    ~H"""
    <div class="flex flex-col">
      <div class="flex flex-row items-center">
        <.expander topic={@topic} />
        <.topic_hierarchy_name topic={@topic} />
        <.topic_merge_button topic={@topic} />
      </div>
      <div class="flex flex-col" id={"topic-outline-#{@topic.id}"}>
        <div :for={{topic, index} <- Enum.with_index(@topic.child_topics)} class="flex flex-row">
          <.nesting_indicator index={index} count={Enum.count(@topic.child_topics) - 1} />
          <.topic_outline topic={topic} index={index} count={Enum.count(@topic.child_topics) - 1} />
        </div>
      </div>
    </div>
    """
  end

  defp expander(%{topic: %{child_topics: [_ | _]}} = assigns) do
    ~H"""
    <.link phx-click={
      JS.toggle(to: "#expander-#{@topic.id}")
      |> JS.toggle(to: "#topic-outline-#{@topic.id}")
      |> JS.toggle(to: "#unexpander-#{@topic.id}")
    }>
      <span
        id={"unexpander-#{@topic.id}"}
        class="hero-chevron-right mt-0.5 w-5 h-5 flex-none"
        style="display: block;"
      />
      <span
        id={"expander-#{@topic.id}"}
        class="hero-chevron-down mt-0.5 w-5 h-5 flex-none"
        style="display: none;"
      />
    </.link>
    """
  end

  defp expander(%{topic: %{child_topics: []}} = assigns), do: ~H""

  defp topic_merge_button(%{topic: %{hierarchy?: false}} = assigns), do: ~H""

  defp topic_merge_button(%{topic: %{hierarchy?: true}} = assigns) do
    ~H"""
    <.link phx-click="merge-topic" phx-value-topic-id={@topic.id}>
      <.icon name="hero-plus" class="h-5 w-5" />
    </.link>
    """
  end

  attr(:index, :integer, required: false, default: nil)
  attr(:count, :integer, required: false, default: nil)

  defp nesting_indicator(%{index: index, count: count} = assigns) when index == 0 and count > 0 do
    ~H"""
    <div class="border-r border-secondary mx-2 w-0" />
    """
  end

  defp nesting_indicator(assigns) do
    ~H"""
    <div class="px-2"></div>
    """
  end

  attr(:topic, Topic, required: true)

  defp topic_hierarchy_name(%{topic: %{hierarchy?: true}} = assigns) do
    ~H"""
    <div class="p-1">
      <%= @topic.model_title %>
    </div>
    """
  end

  defp topic_hierarchy_name(%{topic: %{hierarchy?: false}} = assigns) do
    ~H"""
    <.link patch={~p"/topics/#{@topic}"} class="p-1 underline">
      <%= @topic.title || name_from_keywords(@topic) %>
    </.link>
    """
  end

  defp topic_hierarchy_name(assigns) do
    ~H"""
    <div class="p-1">
      <%= @topic.model_title %>
    </div>
    """
  end

  defp name_from_keywords(%{keywords: keywords}),
    do: Enum.map(keywords, & &1["keyword"]) |> Enum.join("\n")

  defp migration_status(%Topic{to_topic: nil}), do: nil

  defp migration_status(%Topic{to_topic: %Topic{} = to_topic} = topic) do
    attrs =
      to_topic
      |> Map.from_struct()
      |> Map.take([:title, :model_title, :description, :model_description])

    Topic.changeset(topic, attrs)
    |> case do
      %{changes: changes} when changes == %{} -> :migrated
    end
  end

  defp score(%Topic{to_topic: nil}), do: 0

  defp score(%Topic{to_topic: %Topic{} = to} = topic),
    do: floor(Keywords.calculate_score(topic, to) * 100)
end
