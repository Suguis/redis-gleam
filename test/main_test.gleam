import consts
import gleam/erlang/process.{type Subject}
import gleam/otp/supervisor.{type Message}
import gleeunit
import glisten.{type StartError}
import server
import simplifile

pub fn main() {
  let assert Ok(_) = setup_server()
  gleeunit.main()
}

fn setup_server() -> Result(Subject(Message), StartError) {
  let assert Ok(_) =
    consts.rdb_file_contents
    |> simplifile.write_bits(
      to: consts.rdb_file_dir <> "/" <> consts.rdb_file_name,
    )
  server.new(consts.server_config) |> glisten.serve(consts.server_port)
}
