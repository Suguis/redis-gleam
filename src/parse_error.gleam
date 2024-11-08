import gleam/int
import gleam/option.{type Option, None, Some}
import resp

pub type ParseError {
  EmptyInput
  Expected(expected: String, actual: Option(String))
  InvalidSize(expected: Int, actual: Int)
  UnknownType
}

pub fn to_string(err: ParseError) -> String {
  case err {
    EmptyInput -> "unexpected empty input"
    Expected(expected, None) -> "not found expected '" <> expected <> "'"
    Expected(expected, Some(actual)) ->
      "expected " <> expected <> ", found: " <> actual
    InvalidSize(expected, actual) ->
      "unexpected size of element '"
      <> actual |> int.to_string
      <> "', expected '"
      <> expected |> int.to_string
      <> "'"
    UnknownType -> "unknown redis type"
  }
  |> resp.BulkString
  |> resp.to_string
}
