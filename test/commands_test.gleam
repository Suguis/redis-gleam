import carpenter/table
import gleam/function
import gleeunit/should
import redis/commands.{Echo, Get, Ping, Set}
import redis/types.{Array, BulkString, Null, SimpleString}
import utils

pub fn command_parsing_test() {
  [
    #(Array([BulkString("ping")]), Ping),
    #(Array([BulkString("PING")]), Ping),
    #(Array([BulkString("echo"), BulkString("chic")]), Echo("chic")),
    #(Array([BulkString("get"), BulkString("foo")]), Get("foo")),
    #(
      Array([BulkString("set"), BulkString("foo"), BulkString("bar")]),
      Set("foo", "bar"),
    ),
  ]
  |> utils.test_ok_cases(commands.parse)
}

pub fn pong_echo_processing_test() {
  [#(Ping, SimpleString("PONG")), #(Echo("hey"), BulkString("hey"))]
  |> utils.test_cases(commands.process(_, utils.empty_table()))
}

pub fn set_processing_test() {
  let table = utils.empty_table()

  commands.process(Set("foo", "bar"), table)
  |> should.equal(SimpleString("OK"))
  table.lookup(table, "foo") |> should.equal([#("foo", "bar")])
}

pub fn get_processing_test() {
  let table =
    utils.empty_table() |> function.tap(table.insert(_, [#("foo", "bar")]))

  [#(Get("foo"), BulkString("bar")), #(Get("baz"), Null)]
  |> utils.test_cases(commands.process(_, table))
}

pub fn invalid_command_parsing_test() {
  [
    SimpleString(""),
    SimpleString("INVALID"),
    SimpleString("ping"),
    Array([BulkString("")]),
    Array([BulkString("echo")]),
    Array([]),
  ]
  |> utils.test_errors(commands.parse)
}
