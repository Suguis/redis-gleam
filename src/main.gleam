import gleam/erlang/process
import gleam/option.{None}
import glisten
import server

pub fn main() {
  let assert Ok(_) =
    glisten.handler(fn(_conn) { #(Nil, None) }, server.handler)
    |> glisten.serve(6379)

  process.sleep_forever()
}
