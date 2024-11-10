import bravo
import bravo/uset.{type USet}
import command
import command_error
import gleam/bit_array
import gleam/bytes_builder
import gleam/list
import gleam/option.{None}
import gleam/otp/actor
import gleam/result
import gleam/string
import glisten.{type Connection, type Handler, type Message, Packet}
import parse_error
import parser
import rdb
import resp
import simplifile

const store_table_name = "redis"

const config_table_name = "redis-config"

pub type State {
  State(store: USet(#(String, String)), config: USet(#(String, String)))
}

pub fn new(config_params: List(#(String, String))) -> Handler(_, State) {
  let config = setup_table(config_table_name, config_params)
  let state_values = case
    list.key_find(config_params, "dir"),
    list.key_find(config_params, "dbfilename")
  {
    Ok(dir), Ok(dbfilename) -> {
      let assert Ok(contents) = simplifile.read_bits(dir <> "/" <> dbfilename)
      let assert Ok(state_values) = rdb.parse(contents)
      state_values
    }
    _, _ -> []
  }
  let store = setup_table(store_table_name, state_values)

  glisten.handler(fn(_conn) { #(State(store:, config:), None) }, handler)
}

fn handler(msg: Message(_), state: State, conn: Connection(_)) {
  let assert Packet(msg) = msg
  let response = process_response(msg, state) |> bytes_builder.from_string
  let assert Ok(_) = glisten.send(conn, response)
  actor.continue(state)
}

fn process_response(msg: BitArray, state: State) -> String {
  msg
  |> bit_array.to_string
  |> result.replace_error(
    resp.BulkString("invalid utf8 string") |> resp.to_string,
  )
  |> result.map(respond(_, state))
  |> result.flatten
  |> result.map(string.concat)
  |> result.unwrap_both
}

fn respond(input: String, state: State) -> Result(List(String), String) {
  use request_types <- result.try(
    parser.parse(input) |> result.map_error(parse_error.to_string),
  )
  use commands <- result.try(
    request_types
    |> list.map(command.parse)
    |> result.all
    |> result.map_error(command_error.to_string),
  )

  commands
  |> list.map(fn(command) {
    command.process(command, state.store, state.config) |> resp.to_string
  })
  |> Ok
}

fn setup_table(name: String, values: List(#(a, b))) -> uset.USet(#(a, b)) {
  let assert Ok(table) = uset.new(name, 1, bravo.Public)
  uset.insert(table, values)
  table
}
