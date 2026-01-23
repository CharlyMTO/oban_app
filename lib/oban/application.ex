defmodule ObanApp.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      ObanWeb.Telemetry,
      ObanApp.Repo,
      {DNSCluster, query: Application.get_env(:oban_app, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: ObanApp.PubSub},
      # Start Oban
      {Oban, Application.fetch_env!(:oban_app, Oban)},
      # Start ChromicPDF
      {ChromicPDF,
       discard_stderr: false},
      # Start a worker by calling: Oban.Worker.start_link(arg)
      # {Oban.Worker, arg},
      # Start to serve requests, typically the last entry
      ObanWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: ObanApp.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    ObanWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
