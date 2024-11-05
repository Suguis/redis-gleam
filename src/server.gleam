import gleam/bit_array
import gleam/bytes_builder
import gleam/erlang/process.{type Selector}
import gleam/option.{type Option, None}
import gleam/otp/actor
import gleam/result
import glisten.{type Connection, type Handler, type Message, Packet}
import redis/commands
import redis/types

pub fn new() -> Handler(_, Nil) {
  glisten.handler(init, handler)
}

fn init(_conn) -> #(Nil, Option(Selector(_))) {
  #(Nil, None)
}

fn handler(msg: Message(_), state: Nil, conn: Connection(_)) {
  let assert Packet(msg) = msg
  // todo: divide inline responses like Packet("+PING\r\n+PING\r\n")
  let response = process_response(msg) |> bytes_builder.from_string
  let assert Ok(_) = glisten.send(conn, response)
  actor.continue(state)
}

fn process_response(msg: BitArray) -> String {
  let response =
    msg
    |> bit_array.to_string
    |> result.replace_error("invalid utf8 string")
    |> result.map(respond)
    |> result.flatten
  case response {
    Ok(response) -> response
    Error(msg) -> msg <> "\r\n"
  }
}

fn respond(input: String) -> Result(String, String) {
  use request_type <- result.try(types.parse(input))
  use command <- result.try(commands.parse(request_type))

  commands.process(command) |> types.to_string |> Ok
}
