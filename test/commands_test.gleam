import carpenter/table
import command.{Echo, Get, Ping, Set}
import gleam/function
import gleam/option.{None, Some}
import gleeunit/should
import resp.{Array, BulkString, Null, SimpleString}
import utils

pub fn command_parsing_test() {
  [
    #(Array([BulkString("ping")]), Ping),
    #(Array([BulkString("PING")]), Ping),
    #(Array([BulkString("echo"), BulkString("chic")]), Echo("chic")),
    #(Array([BulkString("get"), BulkString("foo")]), Get("foo")),
    #(
      Array([BulkString("set"), BulkString("foo"), BulkString("bar")]),
      Set("foo", "bar", None),
    ),
    #(
      Array([
        BulkString("set"),
        BulkString("foo"),
        BulkString("bar"),
        BulkString("px"),
        BulkString("100"),
      ]),
      Set("foo", "bar", px: Some(100)),
    ),
  ]
  |> utils.test_ok_cases(command.parse)
}

pub fn pong_echo_processing_test() {
  [#(Ping, SimpleString("PONG")), #(Echo("hey"), BulkString("hey"))]
  |> utils.test_cases(command.process(_, utils.empty_table()))
}

pub fn set_processing_test() {
  let table = utils.empty_table()

  command.process(Set("foo", "bar", None), table)
  |> should.equal(SimpleString("OK"))
  table.lookup(table, "foo") |> should.equal([#("foo", "bar")])
}

pub fn get_processing_test() {
  let table =
    utils.empty_table() |> function.tap(table.insert(_, [#("foo", "bar")]))

  [#(Get("foo"), BulkString("bar")), #(Get("baz"), Null)]
  |> utils.test_cases(command.process(_, table))
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
  |> utils.test_errors(command.parse)
}
