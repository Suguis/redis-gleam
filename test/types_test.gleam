import redis/types.{SimpleString}
import utils

pub fn type_parsing_test() {
  [#("+PING\r\n", SimpleString("PING"))]
  |> utils.test_ok_cases(types.parse)
}

pub fn invalid_type_parsing_test() {
  ["", "+PING", "PING\r\n"]
  |> utils.test_errors(types.parse)
}

pub fn type_to_string_test() {
  [#(SimpleString("PING"), "+PING\r\n")]
  |> utils.test_cases(types.to_string)
}
