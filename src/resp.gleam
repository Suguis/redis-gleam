import gleam/int
import gleam/list
import gleam/string

pub type RespType {
  SimpleString(String)
  BulkString(String)
  Array(List(RespType))
  Null
}

pub fn to_string(input: RespType) -> String {
  case input {
    SimpleString(str) -> "+" <> str <> "\r\n"
    BulkString(str) ->
      "$" <> string.length(str) |> int.to_string <> "\r\n" <> str <> "\r\n"
    Array(elems) ->
      "*"
      <> list.length(elems) |> int.to_string
      <> "\r\n"
      <> list.map(elems, to_string) |> string.concat
    Null -> "$-1\r\n"
  }
}
