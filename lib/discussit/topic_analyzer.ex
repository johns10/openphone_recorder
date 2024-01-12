defmodule Discussit.TopicAnalyzer do
  alias Discussit.Accounts.Account
  use GenServer

  @default_opts [statement_count: 1_000_000]

  @spec start_link(any()) :: :ignore | {:error, any()} | {:ok, pid()}
  def start_link(default) do
    GenServer.start_link(Discussit.TopicAnalyzer.Server, default)
  end

  def init(state), do: __MODULE__.Server.init(state)

  def initialize(pid, %Account{} = account, opts \\ @default_opts) do
    GenServer.call(pid, {:initialize, account, opts}, 360_000)
  end

  def train(pid, %Account{} = account, opts \\ @default_opts) do
    GenServer.call(pid, {:train, account, opts}, 360_000)
  end

  def state(pid), do: GenServer.call(pid, :state)
end
