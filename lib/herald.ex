defmodule Herald do
  use Application

  alias :poolboy, as: Poolboy

  @poolboy_config [
    name: {:local, :worker},
    worker_module: Herald.Pipeline,
    strategy: :fifo,
    size: Application.get_env(:herald, :pool_size) || 200,
    max_overflow: (Application.get_env(:herald, :pool_size) || 200) + 2
  ]

  def start(_type, _args) do
    children = [
      Poolboy.child_spec(:worker, @poolboy_config)
    ]

    Supervisor.start_link(children, [
      strategy: :one_for_one,
      name: Herald.Supervisor
    ])
  end
end
