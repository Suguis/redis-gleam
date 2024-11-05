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
  |> test_errors(commands.parse)
}

fn test_errors(cases: List(a), tested_function: fn(a) -> Result(_, _)) {
  cases
  |> list.map(fn(c) { tested_function(c) |> should.be_error })
}

fn test_cases(cases: List(#(a, b)), tested_function: fn(a) -> b) {
  list.map(cases, fn(c) {
    let #(initial, expected) = c
    tested_function(initial) |> should.equal(expected)
  })
}
