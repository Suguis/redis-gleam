import gleam/bit_array
import gleam/result
import redis/commands
import redis/types

pub fn process_response(msg: BitArray) -> String {
  let response =
    msg
    |> bit_array.to_string
    |> result.map_error(fn(_) { "invalid utf8 string" })
    |> result.map(respond)
    |> result.flatten
  case response {
    Ok(response) -> response
    Error(msg) -> msg <> "\r\n"
  }
}

fn respond(input: String) -> Result(String, String) {
  use request_type <- result.try(types.parse(input))
  use command <- result.try(commands.parse(request_type))

  commands.process(command) |> types.to_string |> Ok
}
