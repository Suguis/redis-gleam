import gleam/bool
import gleam/int
import gleam/list
import gleam/result
import gleam/string
import redis/types.{type RedisType, Array, BulkString, Null, SimpleString}

pub fn parse(input: String) -> Result(List(RedisType), String) {
  case string.is_empty(input) {
    True -> Error("unexpected empty string")
    False ->
      case parse_loop(input, []) {
        Ok([]) -> Error("could not parse anything")
        Ok(types) -> Ok(list.reverse(types))
        Error(err) -> Error(err)
      }
  }
}

fn parse_loop(
  input: String,
  parsed_types: List(RedisType),
) -> Result(List(RedisType), String) {
  case string.is_empty(input) {
    True -> Ok(parsed_types)
    False -> {
      use #(redis_type, tail) <- result.try(parse_next(input))
      parse_loop(tail, [redis_type, ..parsed_types])
    }
  }
}

fn parse_array_elements(
  input: String,
  size: Int,
) -> Result(#(List(RedisType), String), String) {
  case size {
    0 -> Ok(#([], input))
    size -> {
      use #(redis_type, tail) <- result.try(parse_next(input))
      use #(redis_types, tail) <- result.try(parse_array_elements(
        tail,
        size - 1,
      ))
      Ok(#([redis_type, ..redis_types], tail))
    }
  }
}

fn parse_next(input: String) -> Result(#(RedisType, String), String) {
  case string.pop_grapheme(input) {
    Ok(#(fb, tail)) ->
      case fb {
        "+" -> {
          use #(str, tail) <- result.try(parse_until_eol(tail))
          Ok(#(SimpleString(str), tail))
        }
        "*" -> {
          use #(digit, tail) <- result.try(parse_until_eol(tail))
          use digit <- result.try(
            int.parse(digit)
            |> result.replace_error("expected digit, got: " <> digit),
          )
          use #(elements, tail) <- result.try(parse_array_elements(tail, digit))
          Ok(#(Array(elements), tail))
        }
        "$" -> {
          use #(digit, tail) <- result.try(parse_until_eol(tail))
          use digit <- result.try(
            int.parse(digit)
            |> result.replace_error("expected digit, got: " <> digit),
          )
          case digit {
            -1 -> Ok(#(Null, tail))
            digit -> {
              use #(str, tail) <- result.try(parse_n_graphemes(tail, digit))
              use tail <- result.try(consume_until_eol(tail))
              Ok(#(BulkString(str), tail))
            }
          }
        }
        _ -> Error("unknown redis type")
      }
    Error(_) -> Error("unexpected empty string")
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
