import gleam/erlang/process
import glisten
import server

pub fn main() {
  let assert Ok(_) = server.new() |> glisten.serve(6379)

  process.sleep_forever()
}
