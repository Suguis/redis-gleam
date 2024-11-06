import redis/parser
import redis/types.{Array, BulkString, Null, SimpleString}
import utils

pub fn type_parsing_test() {
  [
    #("+PING\r\n", [SimpleString("PING")]),
    #("$4\r\nPING\r\n", [BulkString("PING")]),
    #("$2\r\nPING\r\n", [BulkString("PI")]),
    #("*2\r\n+PING\r\n$4\r\nPING\r\n", [
      Array([SimpleString("PING"), BulkString("PING")]),
    ]),
    #("+PING\r\n+PONG\r\n", [SimpleString("PING"), SimpleString("PONG")]),
    #("$-1\r\n", [Null]),
    #("*1\r\n*2\r\n+PING\r\n$4\r\nPING\r\n", [
      Array([Array([SimpleString("PING"), BulkString("PING")])]),
    ]),
  ]
  |> utils.test_ok_cases(parser.parse)
}

pub fn invalid_type_parsing_test() {
  ["", "PING\r\n", "+PING", "$6\r\nPING\r\n", "$4PING\r\n", "$4\r\nPING"]
  |> utils.test_errors(parser.parse)
}

pub fn type_to_string_test() {
  [
    #(SimpleString("PING"), "+PING\r\n"),
    #(BulkString("PING"), "$4\r\nPING\r\n"),
    #(
      Array([SimpleString("PING"), BulkString("PING")]),
      "*2\r\n+PING\r\n$4\r\nPING\r\n",
    ),
  ]
  |> utils.test_cases(types.to_string)
}
