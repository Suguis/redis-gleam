import gleeunit/should
import redis/types.{SimpleString}

pub fn correct_simple_string_parse_test() {
  types.parse("+PING\r\n")
  |> should.equal(Ok(SimpleString("PING")))
}

pub fn empty_string_doesnt_parse_test() {
  types.parse("")
  |> should.be_error
}

pub fn incorrect_simple_string_doesnt_parse_test() {
  types.parse("+PING")
  |> should.be_error
}
