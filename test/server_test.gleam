import consts
import gleam/bit_array
import mug
import utils

pub fn ping_test() {
  [
    #("*1\r\n$4\r\nPING\r\n", "+PONG\r\n"),
    #("*1\r\n$4\r\nping\r\n", "+PONG\r\n"),
    #("*2\r\n$4\r\nECHO\r\n$3\r\nhey\r\n", "$3\r\nhey\r\n"),
  ]
  |> utils.test_cases(send_to_server)
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
