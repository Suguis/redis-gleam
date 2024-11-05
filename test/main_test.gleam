import consts
import gleam/erlang/process.{type Subject}
import gleam/otp/supervisor.{type Message}
import gleeunit
import glisten.{type StartError}
import server

pub fn main() {
  let assert Ok(_) = setup_server()
  gleeunit.main()
}

fn setup_server() -> Result(Subject(Message), StartError) {
  server.new() |> glisten.serve(consts.server_port)
}
