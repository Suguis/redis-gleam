import gleam/list
import gleeunit/should
import redis/commands.{Ping}
import redis/types.{SimpleString}

pub fn command_parsing_test() {
  [#(SimpleString("PING"), Ok(Ping))]
  |> test_cases(commands.parse)
}

pub fn command_processing_test() {
  [#(Ping, SimpleString("PONG"))]
  |> test_cases(commands.process)
}

pub fn invalid_command_parsing_test() {
  [SimpleString(""), SimpleString("INVALID")]
  |> list.map(fn(redis_type) { commands.parse(redis_type) |> should.be_error })
}

fn test_cases(cases: List(#(a, b)), tested_function: fn(a) -> b) {
  list.map(cases, fn(c) {
    let #(initial, expected) = c
    tested_function(initial) |> should.equal(expected)
  })
}
