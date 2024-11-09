import carpenter/table
import command.{ConfigGet, Echo, Get, Ping, Set, SetArgs}
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
      Set("foo", "bar", SetArgs(px: None)),
    ),
    #(
      Array([
        BulkString("set"),
        BulkString("foo"),
        BulkString("bar"),
        BulkString("px"),
        BulkString("100"),
      ]),
      Set("foo", "bar", SetArgs(px: Some(100))),
    ),
    #(
      Array([BulkString("config"), BulkString("get"), BulkString("dir")]),
      ConfigGet("dir"),
    ),
  ]
  |> utils.test_ok_cases(command.parse)
}

pub fn pong_echo_processing_test() {
  [#(Ping, SimpleString("PONG")), #(Echo("hey"), BulkString("hey"))]
  |> utils.test_cases(command.process(
    _,
    store_table: utils.empty_table(),
    config_table: utils.empty_table(),
  ))
}

pub fn set_processing_test() {
  let store_table = utils.empty_table()

  command.process(
    Set("foo", "bar", SetArgs(px: None)),
    store_table:,
    config_table: utils.empty_table(),
  )
  |> should.equal(SimpleString("OK"))
  table.lookup(store_table, "foo") |> should.equal([#("foo", "bar")])
}

pub fn get_processing_test() {
  let store_table =
    utils.empty_table() |> function.tap(table.insert(_, [#("foo", "bar")]))

  [#(Get("foo"), BulkString("bar")), #(Get("baz"), Null)]
  |> utils.test_cases(command.process(
    _,
    store_table:,
    config_table: utils.empty_table(),
  ))
}

pub fn config_get_processing_test() {
  let config_table =
    utils.empty_table()
    |> function.tap(table.insert(_, [
      #("dir", "/tmp/redis-files"),
      #("dbfilename", "dump.rdb"),
    ]))

  [
    #(
      ConfigGet("dir"),
      Array([BulkString("dir"), BulkString("/tmp/redis-files")]),
    ),
    #(
      ConfigGet("dbfilename"),
      Array([BulkString("dbfilename"), BulkString("dump.rdb")]),
    ),
    #(ConfigGet("unknown"), Array([])),
  ]
  |> utils.test_cases(command.process(
    _,
    store_table: utils.empty_table(),
    config_table:,
  ))
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
