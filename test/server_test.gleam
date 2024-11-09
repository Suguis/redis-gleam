import consts
import gleam/bit_array
import gleam/erlang/process
import gleam/int
import gleam/list
import gleam/string
import mug
import resp.{Array, BulkString}
import utils

pub fn ping_test() {
  [#("PING", "+PONG\r\n"), #("ping", "+PONG\r\n")]
  |> utils.test_cases(send_command_to_server)
}

pub fn echo_test() {
  [#("ECHO hey", "$3\r\nhey\r\n")]
  |> utils.test_cases(send_command_to_server)
}

pub fn set_get_test() {
  [
    #("SET foo bar", "+OK\r\n"),
    #("GET foo", "$3\r\nbar\r\n"),
    #("GET baz", "$-1\r\n"),
  ]
  |> utils.test_cases(send_command_to_server)
}

pub fn set_px_test() {
  let time = 20
  [
    #("SET foo_px bar PX " <> int.to_string(time), "+OK\r\n"),
    #("GET foo_px", "$3\r\nbar\r\n"),
  ]
  |> utils.test_cases(send_command_to_server)

  process.sleep(time + 5)

  [#("GET foo_px", "$-1\r\n")]
  |> utils.test_cases(send_command_to_server)
}

pub fn config_get_test() {
  [
    #("CONFIG GET dir", "*2\r\n$3\r\ndir\r\n$16\r\n/tmp/redis-files\r\n"),
    #("CONFIG GET dbfilename", "*2\r\n$10\r\ndbfilename\r\n$8\r\ndump.rdb\r\n"),
  ]
  |> utils.test_cases(send_command_to_server)
}

pub fn keys_test() {
  [#("SET foo bar", "+OK\r\n"), #("KEYS *", "*1\r\n$3\r\nfoo\r\n")]
  |> utils.test_cases(send_command_to_server)
}

fn send_command_to_server(command: String) -> String {
  send_to_server(redis_cli_to_string(command))
}

fn send_to_server(input: String) -> String {
  let assert Ok(socket) =
    mug.new("localhost", consts.server_port)
    |> mug.connect()

  let assert Ok(_) = mug.send(socket, <<input:utf8>>)
  let assert Ok(packet) = mug.receive(socket, timeout_milliseconds: 100)
  let assert Ok(_) = mug.shutdown(socket)
  let assert Ok(output) = packet |> bit_array.to_string
  output
}

fn redis_cli_to_string(command: String) -> String {
  Array(command |> string.split(" ") |> list.map(BulkString)) |> resp.to_string
}
