import gleam/list
import gleam/option.{Some}
import gleam/regex
import gleam/result
import gleam/string

pub type RedisType {
  SimpleString(String)
}

pub fn parse(input: String) -> Result(RedisType, String) {
  use #(first, _) <- result.try(
    string.pop_grapheme(input) |> result.replace_error("empty request"),
  )
  case first {
    "+" -> parse_simple_string(input)
    _ -> Error("invalid redis type")
  }
}

fn parse_simple_string(input: String) -> Result(RedisType, String) {
  let assert Ok(re) = regex.from_string("\\+(.*)\r\n")
  use regex.Match(_, groups) <- result.try(
    regex.scan(with: re, content: input)
    |> list.first
    |> result.replace_error("invalid simple string"),
  )
  let assert Ok(Some(str)) = list.first(groups)
  Ok(SimpleString(str))
}

pub fn to_string(input: RedisType) -> String {
  case input {
    SimpleString(str) -> "+" <> str <> "\r\n"
  }
}
