import gleam/bool
import gleam/int
import gleam/list
import gleam/result
import gleam/string
import redis/types.{type RedisType, BulkString, SimpleString}

pub type ParserTask {
  Free
  ReadingArray(remaining: Int, read_types: List(RedisType))
}

pub type ParseResult =
  Result(#(ParserTask, List(RedisType)), String)

pub fn parse(input: String) -> Result(List(RedisType), String) {
  case string.is_empty(input) {
    True -> Error("unexpected empty string")
    False ->
      case parse_loop(input, Free, []) {
        Ok(#(Free, [])) -> Error("could not parse anything")
        Ok(#(Free, types)) -> Ok(list.reverse(types))
        Ok(#(_, _)) -> Error("parsing ended without finishing to parse a type")
        Error(err) -> Error(err)
      }
  }
}

fn parse_loop(
  input: String,
  state: ParserTask,
  parsed_types: List(RedisType),
) -> ParseResult {
  case string.pop_grapheme(input) {
    Ok(#(fb, tail)) ->
      case fb {
        "+" -> {
          use #(str, tail) <- result.try(parse_until_eol(tail))
          handle_parsing_state(tail, state, SimpleString(str), parsed_types)
        }
        "*" -> {
          use #(digit, tail) <- result.try(parse_until_eol(tail))
          use digit <- result.try(
            int.parse(digit)
            |> result.replace_error("expected digit, got: " <> digit),
          )
          parse_loop(tail, ReadingArray(digit, []), parsed_types)
        }
        "$" -> {
          use #(digit, tail) <- result.try(parse_until_eol(tail))
          use digit <- result.try(
            int.parse(digit)
            |> result.replace_error("expected digit, got: " <> digit),
          )
          use #(str, tail) <- result.try(parse_n_graphemes(tail, digit))
          use tail <- result.try(consume_until_eol(tail))
          handle_parsing_state(tail, state, BulkString(str), parsed_types)
        }
        _ -> Error("unknown redis type")
      }
    Error(_) -> Ok(#(state, parsed_types))
  }
}

fn handle_parsing_state(
  input: String,
  state: ParserTask,
  parsed_type: RedisType,
  parsed_types: List(RedisType),
) -> ParseResult {
  case state {
    Free -> parse_loop(input, Free, [parsed_type, ..parsed_types])
    ReadingArray(1, read_types) ->
      parse_loop(input, Free, [
        types.Array(list.reverse([parsed_type, ..read_types])),
        ..parsed_types
      ])
    ReadingArray(n, read_types) ->
      parse_loop(
        input,
        ReadingArray(n - 1, [parsed_type, ..read_types]),
        parsed_types,
      )
  }
}

fn parse_until_eol(input: String) -> Result(#(String, String), String) {
  string.split_once(input, on: "\r\n")
  |> result.replace_error("expected eol")
}

fn parse_n_graphemes(input: String, n: Int) -> Result(#(String, String), String) {
  use <- bool.guard(
    string.length(input) < n,
    Error("the value to take is too large for the input"),
  )
  Ok(#(
    string.slice(input, at_index: 0, length: n),
    string.drop_left(input, up_to: n),
  ))
}

fn consume_until_eol(input: String) -> Result(String, String) {
  use #(_, tail) <- result.try(parse_until_eol(input))
  Ok(tail)
}
