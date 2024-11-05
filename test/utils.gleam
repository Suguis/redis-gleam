import gleam/list
import gleeunit/should

pub fn test_errors(cases: List(a), tested_function: fn(a) -> Result(_, _)) {
  cases
  |> list.map(fn(c) { tested_function(c) |> should.be_error })
}

pub fn test_cases(cases: List(#(a, b)), tested_function: fn(a) -> b) {
  list.map(cases, fn(c) {
    let #(initial, expected) = c
    tested_function(initial) |> should.equal(expected)
  })
}
