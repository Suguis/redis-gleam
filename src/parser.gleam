import gleam/bool
import gleam/int
import gleam/list
import gleam/option.{None, Some}
import gleam/result
import gleam/string
import parse_error.{type ParseError}
import resp.{type RespType, Array, BulkString, Null, SimpleString}

pub fn parse(input: String) -> Result(List(RespType), ParseError) {
  case string.is_empty(input) {
    True -> Error(parse_error.EmptyInput)
    False ->
      case parse_loop(input, []) {
        Ok([]) -> Error(parse_error.EmptyInput)
        Ok(types) -> Ok(list.reverse(types))
        Error(err) -> Error(err)
      }
  }
}

fn parse_loop(
  input: String,
  parsed_types: List(RespType),
) -> Result(List(RespType), ParseError) {
  case string.is_empty(input) {
    True -> Ok(parsed_types)
    False -> {
      use #(resp_type, tail) <- result.try(parse_next(input))
      parse_loop(tail, [resp_type, ..parsed_types])
    }
  }
}

fn parse_next(input: String) -> Result(#(RespType, String), ParseError) {
  case input {
    "+" <> tail -> {
      use #(str, tail) <- result.try(parse_until_eol(tail))
      Ok(#(SimpleString(str), tail))
    }
    "*" <> tail -> {
      use #(digit, tail) <- result.try(parse_until_eol(tail))
      use digit <- result.try(
        int.parse(digit)
        |> result.replace_error(parse_error.Expected("digit", Some(digit))),
      )
      use #(elements, tail) <- result.try(parse_array_elements(tail, digit))
      Ok(#(Array(elements), tail))
    }
    "$-1\r\n" <> tail -> Ok(#(Null, tail))
    "$" <> tail -> {
      use #(digit, tail) <- result.try(parse_until_eol(tail))
      use digit <- result.try(
        int.parse(digit)
        |> result.replace_error(parse_error.Expected("digit", Some(digit))),
      )
      use #(str, tail) <- result.try(parse_n_graphemes(tail, digit))
      use tail <- result.try(consume_until_eol(tail))
      Ok(#(BulkString(str), tail))
    }
    _ -> Error(parse_error.UnknownType)
  }
}

fn parse_array_elements(
  input: String,
  size: Int,
) -> Result(#(List(RespType), String), ParseError) {
  case size {
    0 -> Ok(#([], input))
    size -> {
      use #(resp_type, tail) <- result.try(parse_next(input))
      use #(resp_types, tail) <- result.try(parse_array_elements(tail, size - 1))
      Ok(#([resp_type, ..resp_types], tail))
    }
  }
}

fn parse_until_eol(input: String) -> Result(#(String, String), ParseError) {
  string.split_once(input, on: "\r\n")
  |> result.replace_error(parse_error.Expected("\\r\\n", None))
}

fn parse_n_graphemes(
  input: String,
  n: Int,
) -> Result(#(String, String), ParseError) {
  use <- bool.guard(
    string.length(input) < n,
    Error(parse_error.InvalidSize(n, string.length(input))),
  )
  Ok(#(
    string.slice(input, at_index: 0, length: n),
    string.drop_left(input, up_to: n),
  ))
}

fn consume_until_eol(input: String) -> Result(String, ParseError) {
  use #(_, tail) <- result.try(parse_until_eol(input))
  Ok(tail)
}
