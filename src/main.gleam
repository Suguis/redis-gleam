import argv
import gleam/erlang/process
import gleam/io
import glisten
import server

pub fn main() {
  case read_args(argv.load().arguments) {
    Ok(config) -> {
      let assert Ok(_) = server.new(config) |> glisten.serve(6379)
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
    ["--dir", dir, ..args] -> read_args_loop(args, [#("dir", dir), ..result])
    ["--dbfilename", dbfilename, ..args] ->
      read_args_loop(args, [#("dbfilename", dbfilename), ..result])
    _ -> Error("invalid args")
  }
}
