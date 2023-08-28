defmodule Processor.Server do
  use GenServer

  defstruct data: nil, lock: {false, nil, nil}

  @state __MODULE__
  @lock_timeout Application.compile_env(:processor, :lock_timeout)
  @request_timeout Application.compile_env(:processor, :request_timeout)

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: :processor_server)
  end

  # GenServer callback functions

  def init(data: data) do
    state = %@state{data: data}
    {:ok, state}
  end

  # timeout of waiting write of new data from a process which have locked the data by dirty_read
  def handle_info(
        {:timeout, timer, {:"expired timeout", pid}},
        state = %@state{lock: {true, timer, pid}}
      ) do
    new_state = %{state | lock: {false, nil, nil}}
    {:noreply, new_state}
  end

  # the same timeout but the message is handled too late
  # the server has already wrote the new data and released the lock
  # this is the case when the timeout message being after the write message in the server's mailbox queue
  def handle_info({:timeout, _timer, {:"expired timeout", _pid}}, state) do
    {:noreply, state}
  end

  # the data has been already locked and can't be accessed
  # each dirty_read is always followed by write from the same process 
  # that's why we should use a lock to prevent data loss
  # the server puts this message again in the mailbox queue, hoping the next time will succeed
  def handle_info({:dirty_read, _from} = msg, state = %@state{lock: {true, _timer, _pid}}) do
    send(self(), msg)
    {:noreply, state}
  end

  # the data is free of lock and can be accessed by dirty_read
  def handle_info({:dirty_read, from}, state = %@state{data: data, lock: {false, nil, nil}}) do
    send_reply(from, data)
    timer = :erlang.start_timer(@lock_timeout, self(), {:"expired timeout", from})
    new_state = %{state | lock: {true, timer, from}}
    {:noreply, new_state}
  end

  # a safe_read will not be followed by a write
  # this is the case for just loading data for the first time or searching substrings 
  def handle_info({:safe_read, from}, state = %@state{data: data}) do
    send_reply(from, data)
    {:noreply, state}
  end

  # a write message from a process which has already locked the data
  def handle_info({:write, from, new_data}, %@state{lock: {true, timer, from}}) do
    :erlang.cancel_timer(timer)
    send_reply(from, :done)
    new_state = %@state{data: new_data, lock: {false, nil, nil}}
    {:noreply, new_state}
  end

  # A process which has not locked the data by dirty_read, can't never write new data
  # A process which has locked the data by dirty_read and exceed the lock_timeout, can't write new data
  def handle_info({:write, _from, _new_data}, state) do
    {:noreply, state}
  end

  # server API

  def dirty_read(), do: rpc({:dirty_read, self()})

  def safe_read(), do: rpc({:safe_read, self()})

  def write(data), do: rpc({:write, self(), data})

  # private functions

  defp send_reply(to, reply) do
    send(to, {:reply, reply})
  end

  defp rpc(msg) do
    send(:processor_server, msg)

    receive do
      {:reply, _reply} = res -> res
    after
      @request_timeout -> :noreply
    end
  end
end
