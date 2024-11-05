import gleam/bytes_builder
import gleam/erlang/process
import gleam/option.{None}
import gleam/otp/actor
import glisten.{Packet}
import server

pub fn main() {
  let assert Ok(_) =
    glisten.handler(fn(_conn) { #(Nil, None) }, fn(msg, state, conn) {
      let assert Packet(msg) = msg
      // todo: divide inline responses like Packet("+PING\r\n+PING\r\n")
      let response = server.process_response(msg) |> bytes_builder.from_string
      let assert Ok(_) = glisten.send(conn, response)
      actor.continue(state)
    })
    |> glisten.serve(6379)

  process.sleep_forever()
}
