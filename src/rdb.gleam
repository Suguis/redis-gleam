import gleam/bit_array
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import tempo
import tempo/datetime

pub fn parse(
  input: BitArray,
) -> Result(List(#(String, String, option.Option(tempo.DateTime))), String) {
  use input <- result.try(parse_header(input))
  parse_loop(input, [])
}

fn parse_loop(
  input: BitArray,
  result: List(#(String, String, Option(tempo.DateTime))),
) -> Result(List(#(String, String, Option(tempo.DateTime))), String) {
  case input {
    <<0xfa, rest:bits>> -> {
      use rest <- result.try(parse_metadata(rest))
      parse_loop(rest, result)
    }
    <<0xfe, _:int, 0xfb, keys:int, _:int, rest:bits>> -> {
      use #(list, rest) <- result.try(parse_database(rest, keys))
      parse_loop(rest, list.append(result, list))
    }
    <<0xff, _:bits>> -> Ok(result)
    _ -> Error("invalid section")
  }
}

fn parse_metadata(input: BitArray) -> Result(BitArray, String) {
  use #(_key, rest) <- result.try(parse_string(input))
  use #(_value, rest) <- result.try(parse_string(rest))
  Ok(rest)
}

fn parse_database(
  input: BitArray,
  keys: Int,
) -> Result(
  #(List(#(String, String, Option(tempo.DateTime))), BitArray),
  String,
) {
  case input, keys {
    input, 0 -> Ok(#([], input))
    <<0x00, rest:bits>>, keys -> parse_database_entry(rest, keys, None)
    <<0xfc, px:little-size(64), 0x00, rest:bits>>, keys ->
      parse_database_entry(rest, keys, Some(datetime.from_unix_milli_utc(px)))
    <<0xfd, ex:little-size(32), 0x00, rest:bits>>, keys ->
      parse_database_entry(rest, keys, Some(datetime.from_unix_utc(ex)))
    _, _ -> Error("Invalid database section")
  }
}

fn parse_database_entry(
  input: BitArray,
  keys: Int,
  expire_time: Option(tempo.DateTime),
) -> Result(
  #(List(#(String, String, Option(tempo.DateTime))), BitArray),
  String,
) {
  use #(key, rest) <- result.try(parse_string(input))
  use #(value, rest) <- result.try(parse_string(rest))
  use #(list, rest) <- result.try(parse_database(rest, keys - 1))
  Ok(#([#(key, value, expire_time), ..list], rest))
}

fn parse_string(input: BitArray) -> Result(#(String, BitArray), String) {
  case input {
    <<0b11_000000, content:size(8), rest:bits>>
    | <<0b11_000001, content:size(16), rest:bits>>
    | <<0b11_000010, content:size(32), rest:bits>> ->
      Ok(#(content |> int.to_string, rest))
    <<size:int, rest:bits>> -> {
      use str <- result.try(
        bit_array.slice(rest, at: 0, take: size)
        |> result.map(bit_array.to_string)
        |> result.flatten
        |> result.replace_error("error parsing string"),
      )
      use rest <- result.try(
        bit_array.slice(rest, at: size, take: bit_array.byte_size(rest) - size)
        |> result.replace_error("unexpected EOF"),
      )
      Ok(#(str, rest))
    }
    _ -> Error("empty string")
  }
}

fn parse_header(input: BitArray) -> Result(BitArray, String) {
  case input {
    <<"REDIS":utf8, "0011":utf8, rest:bits>> -> Ok(rest)
    _ -> Error("invalid header")
  }
}
