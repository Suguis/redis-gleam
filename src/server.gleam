import gleam/bit_array
import gleam/bytes_builder
import gleam/erlang/process.{type Selector}
import gleam/list
import gleam/option.{type Option, None}
import gleam/otp/actor
import gleam/result
import gleam/string
import glisten.{type Connection, type Handler, type Message, Packet}
import redis/commands
import redis/parser
import redis/types

pub fn new() -> Handler(_, Nil) {
  glisten.handler(init, handler)
}

fn init(_conn) -> #(Nil, Option(Selector(_))) {
  #(Nil, None)
}

fn handler(msg: Message(_), state: Nil, conn: Connection(_)) {
  let assert Packet(msg) = msg
  let response = process_response(msg) |> bytes_builder.from_string
  let assert Ok(_) = glisten.send(conn, response)
  actor.continue(state)
}

fn process_response(msg: BitArray) -> String {
  msg
  |> bit_array.to_string
  |> result.replace_error("invalid utf8 string")
  |> result.map(respond)
  |> result.flatten
  |> result.map_error(string.append(_, "\r\n"))
  |> result.map(string.concat)
  |> result.unwrap_both
}

fn respond(input: String) -> Result(List(String), String) {
  use request_types <- result.try(parser.parse(input))
  use commands <- result.try(
    request_types
    |> list.map(commands.parse)
    |> result.all,
  )

  commands
  |> list.map(fn(command) { commands.process(command) |> types.to_string })
  |> Ok
}
