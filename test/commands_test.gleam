import redis/commands.{Echo, Ping}
import redis/types.{Array, BulkString, SimpleString}
import utils

pub fn command_parsing_test() {
  [
    #(Array([BulkString("ping")]), Ping),
    #(Array([BulkString("PING")]), Ping),
    #(Array([BulkString("echo"), BulkString("chic")]), Echo("chic")),
  ]
  |> utils.test_ok_cases(commands.parse)
}

pub fn command_processing_test() {
  [#(Ping, SimpleString("PONG")), #(Echo("hey"), BulkString("hey"))]
  |> utils.test_cases(commands.process)
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
