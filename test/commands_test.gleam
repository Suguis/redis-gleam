import redis/commands.{Ping}
import redis/types.{SimpleString}
import utils

pub fn command_parsing_test() {
  [#(SimpleString("PING"), Ping)]
  |> utils.test_ok_cases(commands.parse)
}

pub fn command_processing_test() {
  [#(Ping, SimpleString("PONG"))]
  |> utils.test_cases(commands.process)
}

pub fn invalid_command_parsing_test() {
  [SimpleString(""), SimpleString("INVALID")]
  |> utils.test_errors(commands.parse)
}
