Code.require_file("../fixtures/endpoints.exs", __DIR__)
Code.require_file("../fixtures/serializers.exs", __DIR__)

defmodule ElvenGard.SocketTest do
  use ExUnit.Case, async: true

  import ElvenGard.Socket, only: [assign: 2, assign: 3]

  setup_all do
    %{server_pid: start_supervised!(MyApp.EchoEndpoint)}
  end

  ## new

  describe "new/2" do
    test "create a socket" do
      socket = ElvenGard.Socket.new(:foo, :bar)

      assert is_binary(socket.id)
      assert socket.transport_pid == :foo
      assert socket.transport == :bar
      assert socket.serializer == nil
      assert socket.frontend_pid == nil
    end
  end

  describe "new/3" do
    test "create a socket with a serializer" do
      socket = ElvenGard.Socket.new(:foo, :bar, :abc)

      assert is_binary(socket.id)
      assert socket.transport_pid == :foo
      assert socket.transport == :bar
      assert socket.serializer == :abc
      assert socket.frontend_pid == nil
    end
  end

  describe "new/4" do
    test "create a socket with a frontend pid" do
      socket = ElvenGard.Socket.new(:foo, :bar, :abc, :baz)

      assert is_binary(socket.id)
      assert socket.transport_pid == :foo
      assert socket.transport == :bar
      assert socket.serializer == :abc
      assert socket.frontend_pid == :baz
    end
  end

  ## assign

  describe "assign/3" do
    test "assigns to socket" do
      socket = %ElvenGard.Socket{}
      assert socket.assigns[:foo] == nil
      socket = assign(socket, :foo, :bar)
      assert socket.assigns[:foo] == :bar
    end
  end

  describe "assign/2" do
    test "assigns a map socket" do
      socket = %ElvenGard.Socket{}
      assert socket.assigns[:foo] == nil
      socket = assign(socket, %{foo: :bar, abc: :def})
      assert socket.assigns[:foo] == :bar
      assert socket.assigns[:abc] == :def
    end

    test "merges if values exist" do
      socket = %ElvenGard.Socket{}
      socket = assign(socket, %{foo: :bar, abc: :def})
      socket = assign(socket, %{foo: :baz})
      assert socket.assigns[:foo] == :baz
      assert socket.assigns[:abc] == :def
    end

    test "merges keyword lists" do
      socket = %ElvenGard.Socket{}
      socket = assign(socket, %{foo: :bar, abc: :def})
      socket = assign(socket, foo: :baz)
      assert socket.assigns[:foo] == :baz
      assert socket.assigns[:abc] == :def
    end
  end

  ## send

  describe "send/2" do
    test "can send a message", %{server_pid: server_pid} do
      socket = %ElvenGard.Socket{
        serializer: ElvenGard.Socket.DummySerializer,
        transport_pid: MyApp.EchoEndpoint.subscribe(server_pid),
        transport: :gen_tcp
      }

      assert ElvenGard.Socket.send(socket, "message") == :ok
      assert_receive {:new_message, "message"}
    end

    test "can serialize a message", %{server_pid: server_pid} do
      socket = %ElvenGard.Socket{
        transport_pid: MyApp.EchoEndpoint.subscribe(server_pid),
        transport: :gen_tcp,
        serializer: MyApp.LineSerializer
      }

      assert ElvenGard.Socket.send(socket, "message") == :ok
      assert_receive {:new_message, "message\n"}

      assert ElvenGard.Socket.send(socket, "message", endl: "\r") == :ok
      assert_receive {:new_message, "message\r"}
    end

    test "directly send the packet if self is the frontend", %{server_pid: server_pid} do
      socket = %ElvenGard.Socket{
        serializer: ElvenGard.Socket.DummySerializer,
        transport_pid: MyApp.EchoEndpoint.subscribe(server_pid),
        transport: :gen_tcp,
        frontend_pid: self()
      }

      assert ElvenGard.Socket.send(socket, "message") == :ok
      assert_receive {:new_message, "message"}
    end

    @tag :skip
    test "can delegate a packet to a frontend", %{server_pid: server_pid} do
      frontend_pid = self()

      task =
        Task.async(fn ->
          socket = %ElvenGard.Socket{
            serializer: ElvenGard.Socket.DummySerializer,
            transport_pid: MyApp.EchoEndpoint.subscribe(server_pid),
            transport: :gen_tcp,
            frontend_pid: frontend_pid
          }

          assert ElvenGard.Socket.send(socket, "message") == :ok
          assert_receive {:new_message, "message"}

          socket
        end)

      socket = Task.await(task)
      assert_receive {:send_to, ^socket, "message"}
    end
  end

  ## recv

  describe "recv/3" do
    test "can receive a message", %{server_pid: server_pid} do
      socket = %ElvenGard.Socket{
        serializer: ElvenGard.Socket.DummySerializer,
        transport_pid: MyApp.EchoEndpoint.subscribe(server_pid),
        transport: :gen_tcp
      }

      # Receive available buffer
      :ok = MyApp.EchoEndpoint.send_message(server_pid, "foo")
      assert ElvenGard.Socket.recv(socket) == {:ok, "foo"}

      # Receive only some bytes
      :ok = MyApp.EchoEndpoint.send_message(server_pid, "bar")
      assert ElvenGard.Socket.recv(socket, 1) == {:ok, "b"}
      assert ElvenGard.Socket.recv(socket, 2) == {:ok, "ar"}

      # Set timeout option
      :ok = MyApp.EchoEndpoint.send_message(server_pid, "abc", 100)
      assert ElvenGard.Socket.recv(socket, 0, 1) == {:error, :timeout}
      assert ElvenGard.Socket.recv(socket, 0, 200) == {:ok, "abc"}
    end

    test "can deserialize a message", %{server_pid: server_pid} do
      socket = %ElvenGard.Socket{
        transport_pid: MyApp.EchoEndpoint.subscribe(server_pid),
        transport: :gen_tcp,
        serializer: MyApp.LineSerializer
      }

      # Basic example
      :ok = MyApp.EchoEndpoint.send_message(server_pid, "foo")
      assert ElvenGard.Socket.recv(socket) == {:ok, {:decoded, "foo"}}

      # Support errors
      assert ElvenGard.Socket.recv(socket, 1, 1) == {:error, :timeout}

      # raise "todo"
    end
  end
end
