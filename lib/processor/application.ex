defmodule Processor.Application do
  def start(_type, _args) do
    [
      Application.get_env(:processor, :data),
      Application.get_env(:processor, :lock_timeout),
      Application.get_env(:processor, :request_timeout)
    ]
    |> Enum.member?(nil)
    |> case do
      true ->
        exit("Processor environment variables not all set in configuration")

      _ ->
        data = Application.get_env(:processor, :data)

        children = [
          {Processor.Server, data: data}
        ]

        sup_flags = [
          strategy: :one_for_one,
          max_restarts: 1,
          max_seconds: 5
        ]

        Supervisor.start_link(children, sup_flags)
    end
  end

  def stop(_) do
    :ok
  end
end
