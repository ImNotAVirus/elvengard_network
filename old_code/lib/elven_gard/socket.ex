defmodule ElvenGard.Socket do
  @moduledoc ~S"""
  Manage a socket

  ## Socket fields

    * `:id` - The string id of the socket
    * `:transport` - A [Ranch transport](https://ninenines.eu/docs/en/ranch/2.0/guide/transports/)
    * `:transport_pid` - The pid of the socket's transport process
    * `:serializer` - The serializer for socket messages, default: `nil`
    * `:frontend_pid` - The map of socket assigns, default: `nil`
    * `:assigns` - The map of socket assigns, default: `%{}`
  """

  alias ElvenGard.{Endpoint, Socket, UUID}

  @default_timeout 5_000

  # @enforce_keys [:id, :socket, :transport]

  defstruct id: nil,
            transport: nil,
            transport_pid: nil,
            serializer: nil,
            frontend_pid: nil,
            assigns: %{}

  @type t :: %Socket{
          id: String.t(),
          transport: atom(),
          transport_pid: pid(),
          serializer: module() | nil,
          frontend_pid: pid() | nil,
          assigns: map()
        }

  @doc """
  Create a new structure
  """
  @spec new(pid(), atom(), module() | nil, pid() | nil) :: Socket.t()
  def new(transport_pid, transport, serializer \\ nil, frontend_pid \\ nil) do
    %Socket{
      id: UUID.uuid4(),
      transport_pid: transport_pid,
      transport: transport,
      serializer: serializer,
      frontend_pid: frontend_pid
    }
  end

  @doc """
  Send a packet to the client.

  If a serializer is found, the function `c:ElvenGard.Codec.encode/2` 
  will be called first with Socket's assigns as the second parameter
  to encode the message.

  The message will then be sent directly to the client if no 
  frontend is found or, otherwise, the corresponding frontend 
  will be notified via `ElvenGard.Endpoint.send/2`.

  ## Examples

      iex> send(socket, "data")
      iex> send(socket, "data", foo: :bar)
  """
  @spec send(Socket.t(), any(), keyword()) :: :ok | {:error, atom()}
  def send(%Socket{} = socket, message, opts \\ []) do
    message
    |> serialize_message(opts, socket)
    |> send_message(socket)
  end

  @doc """
  Receive a packet from the client.

  ...

  ## Examples

      iex> recv(socket)
      iex> recv(socket, 10)
      iex> recv(socket, 0, 10_000)
  """
  @spec recv(Socket.t(), non_neg_integer(), timeout()) ::
          {:ok, data :: any()}
          | {:error, reason :: any()}
  def recv(%Socket{} = socket, length \\ 0, timeout \\ @default_timeout) do
    case receive_message(socket, length, timeout) do
      {:error, _} = error -> error
      {:ok, data} -> handle_in(data, socket)
    end
  end

  @doc """
  Handles incoming socket messages.
  """
  @spec handle_in(iodata(), Socket.t()) ::
          {:ok, data :: any()}
          | {:error, reason :: any()}
  def handle_in(message, %Socket{} = socket) do
    %Socket{serializer: serializer, assigns: assigns} = socket
    {:ok, serializer.decode!(message, assigns)}
  rescue
    e -> {:error, e}
  end

  @doc """
  Adds key value pairs to socket assigns.

  A single key value pair may be passed, a keyword list or map
  of assigns may be provided to be merged into existing socket
  assigns.

  ## Examples

      iex> assign(socket, :name, "ElvenGard")
      iex> assign(socket, name: "ElvenGard", logo: "🌸")
  """
  @spec assign(Socket.t(), atom(), any()) :: Socket.t()
  def assign(%Socket{} = socket, key, value) do
    assign(socket, [{key, value}])
  end

  @spec assign(Socket.t(), map() | keyword()) :: Socket.t()
  def assign(%Socket{} = socket, attrs) when is_map(attrs) or is_list(attrs) do
    %{socket | assigns: Map.merge(socket.assigns, Map.new(attrs))}
  end

  ## Private functions

  @doc false
  defp serialize_message(message, opts, %Socket{} = socket) do
    socket.serializer.encode!(message, opts)
  end

  @doc false
  defp send_message(message, %Socket{frontend_pid: frontend_pid} = socket)
       when is_nil(frontend_pid)
       when frontend_pid == self() do
    %Socket{transport: transport, transport_pid: transport_pid} = socket
    transport.send(transport_pid, message)
  end

  defp send_message(message, %Socket{} = socket) do
    Endpoint.send(socket, message)
  end

  @doc false
  defp receive_message(%Socket{frontend_pid: frontend_pid} = socket, length, timeout)
       when is_nil(frontend_pid)
       when frontend_pid == self() do
    %Socket{transport: transport, transport_pid: transport_pid} = socket
    transport.recv(transport_pid, length, timeout)
  end

  defp receive_message(%Socket{} = socket, length, timeout) do
    Endpoint.recv(socket, length, timeout)
  end
end
