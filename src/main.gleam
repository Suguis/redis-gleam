import argv
import gleam/erlang/process
import gleam/int
import gleam/io
import gleam/list
import gleam/result
import glisten
import server

pub fn main() {
  case read_args(argv.load().arguments) {
    Ok(config) -> {
      let port =
        list.key_find(config, "port")
        |> result.map(int.parse)
        |> result.flatten
        |> result.unwrap(6379)
      let assert Ok(_) = server.new(config) |> glisten.serve(port)
      io.println("redis listening on " <> port |> int.to_string)
      process.sleep_forever()
    }
    Error(msg) -> {
      io.println_error(msg)
    }
  }
}

fn read_args(args: List(String)) -> Result(List(#(String, String)), String) {
  read_args_loop(args, [])
}

fn read_args_loop(
  args: List(String),
  result: List(#(String, String)),
) -> Result(List(#(String, String)), String) {
  case args {
    [] -> Ok(result)
    ["--port", port, ..args] ->
      read_args_loop(args, [#("port", port), ..result])
    ["--dir", dir, ..args] -> read_args_loop(args, [#("dir", dir), ..result])
    ["--dbfilename", dbfilename, ..args] ->
      read_args_loop(args, [#("dbfilename", dbfilename), ..result])
    _ -> Error("invalid args")
  }
}
