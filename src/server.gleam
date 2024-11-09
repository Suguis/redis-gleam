import carpenter/table
import command
import command_error
import gleam/bit_array
import gleam/bytes_builder
import gleam/erlang/process.{type Selector}
import gleam/list
import gleam/option.{type Option, None}
import gleam/otp/actor
import gleam/result
import gleam/string
import glisten.{type Connection, type Handler, type Message, Packet}
import parse_error
import parser
import resp

const store_table_name = "redis"

const config_table_name = "redis-config"

pub fn new(config: List(#(String, String))) -> Handler(_, Nil) {
  setup_table(store_table_name, [])
  setup_table(config_table_name, config)
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
  |> result.replace_error(
    resp.BulkString("invalid utf8 string") |> resp.to_string,
  )
  |> result.map(respond)
  |> result.flatten
  |> result.map(string.concat)
  |> result.unwrap_both
}

fn respond(input: String) -> Result(List(String), String) {
  use request_types <- result.try(
    parser.parse(input) |> result.map_error(parse_error.to_string),
  )
  use commands <- result.try(
    request_types
    |> list.map(command.parse)
    |> result.all
    |> result.map_error(command_error.to_string),
  )

  let assert Ok(store_table) = table.ref(store_table_name)
  let assert Ok(config_table) = table.ref(config_table_name)

  commands
  |> list.map(fn(command) {
    command.process(command, store_table:, config_table:) |> resp.to_string
  })
  |> Ok
}

fn setup_table(name: String, values: List(#(a, b))) {
  let assert Ok(table) =
    table.build(name)
    |> table.privacy(table.Public)
    |> table.write_concurrency(table.AutoWriteConcurrency)
    |> table.read_concurrency(True)
    |> table.compression(False)
    |> table.set

  table.insert(table, values)
}
