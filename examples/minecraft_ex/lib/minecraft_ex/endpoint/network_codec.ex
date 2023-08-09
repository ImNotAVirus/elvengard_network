defmodule MinecraftEx.Endpoint.NetworkCodec do
  @moduledoc """
  Documentation for MinecraftEx.Endpoint.NetworkCodec
  """

  @behaviour ElvenGard.Network.NetworkCodec

  alias MinecraftEx.Types.VarInt
  alias MinecraftEx.ClientPackets

  @impl true
  def next(<<>>), do: {nil, <<>>}

  def next(message) do
    {length, rest} = VarInt.decode(message)

    case byte_size(rest) >= length do
      true ->
        <<raw::binary-size(length), rest::binary>> = rest
        {raw, rest}

      false ->
        {nil, message}
    end
  end

  @impl true
  def deserialize(raw, socket) do
    {packet_id, rest} = VarInt.decode(raw)
    packet = ClientPackets.deserialize(packet_id, rest, socket)

    if is_nil(packet) do
      raise "unable to deserialize packet with id #{inspect(packet_id)} - #{inspect(raw)}"
    end

    packet
  end

  @impl true
  def serialize(struct, socket) when is_struct(struct) do
    {packet_id, params} = struct.__struct__.serialize(struct)
    serialize([VarInt.encode(packet_id), params], socket)
  end

  def serialize(raw, _socket) when is_list(raw) do
    bin = :binary.list_to_bin(raw)
    packet_length = bin |> byte_size() |> VarInt.encode([])
    [<<packet_length::binary>> | bin]
  end
end
