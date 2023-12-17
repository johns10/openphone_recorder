defmodule DiscussitWeb.StatementsLive.Components do
  use Phoenix.Component

  use Phoenix.VerifiedRoutes,
    endpoint: DiscussitWeb.Endpoint,
    router: DiscussitWeb.Router

  attr(:statements, :list, required: true)
  attr(:id, :string, required: true)
  attr(:title, :string, default: "Statements")

  def statements_table(assigns) do
    ~H"""
    <div class="card bg-base-300 overflow-y-hidden">
      <div class="card-body overflow-y-hidden">
        <div class="card-title"><%= @title %></div>
        <div class="overflow-y-auto">
          <table class="table table-zebra">
            <tbody phx-update="stream" id={@id}>
              <tr :for={{id, statement} <- @statements}>
                <td id={id}><%= statement.content %></td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
    </div>
    """
  end
end
