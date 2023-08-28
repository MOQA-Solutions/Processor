defmodule Processor do
  alias Processor.Server

  @spec get() :: {:ok, String.t()}
  def get() do
    {:reply, data} = Server.safe_read()
    {:ok, data}
  end

  @spec insert(substring :: String.t(), position :: pos_integer()) :: {:ok, String.t()}
  def insert(substring, position) do
    {:reply, data} = Server.dirty_read()
    {substring1, substring2} = String.split_at(data, position)
    new_data = substring1 <> substring <> substring2
    {:reply, :done} = Server.write(new_data)
    {:ok, new_data}
  end

  @spec delete(stringlist :: String.t() | [String.t()]) :: {:ok, String.t()}
  def delete(stringlist) do
    {:reply, data} = Server.dirty_read()
    new_data = String.replace(data, stringlist, "", global: true)
    {:reply, :done} = Server.write(new_data)
    {:ok, new_data}
  end

  @spec replace(substring1 :: String.t(), substring2 :: String.t()) :: {:ok, String.t()}
  def replace(substring1, substring2) do
    {:reply, data} = Server.dirty_read()
    new_data = String.replace(data, substring1, substring2, global: true)
    {:reply, :done} = Server.write(new_data)
    {:ok, new_data}
  end

  @spec search(substring :: String.t()) :: :ok | {:ok, {String.t(), String.t(), String.t()}}
  def search(substring) do
    {:reply, data} = Server.safe_read()

    case :binary.match(data, substring) do
      :nomatch ->
        :ok

      {pos, _length} ->
        {substring1, substring0} = String.split_at(data, pos)
        {^substring, substring2} = String.split_at(substring0, String.length(substring))
        {:ok, {substring1, substring, substring2}}
    end
  end
end
