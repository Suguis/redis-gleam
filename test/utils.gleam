import bravo
import bravo/uset
import gleam/int
import gleam/list
import gleeunit/should

pub fn test_errors(cases: List(a), tested_function: fn(a) -> Result(_, _)) {
  cases
  |> list.map(fn(c) { tested_function(c) |> should.be_error })
}

pub fn test_ok_cases(
  cases: List(#(a, b)),
  tested_function: fn(a) -> Result(b, _),
) {
  list.map(cases, fn(c) {
    let #(initial, expected) = c
    tested_function(initial) |> should.equal(Ok(expected))
  })
}

pub fn test_cases(cases: List(#(a, b)), tested_function: fn(a) -> b) {
  list.map(cases, fn(c) {
    let #(initial, expected) = c
    tested_function(initial) |> should.equal(expected)
  })
}

pub fn empty_table() -> uset.USet(#(String, String)) {
  let assert Ok(table) =
    uset.new(int.random(1_000_000) |> int.to_string, 1, bravo.Private)
  table
}
