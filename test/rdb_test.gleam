import gleam/bit_array
import gleeunit/should
import rdb

pub fn parse_test() {
  let input = <<
    "REDIS":utf8, "0011":utf8, 0xfa, 9, "redis-ver":utf8, 6, "6.0.16":utf8, 0xfe,
    0, 0xfb, 3, 2, 0x00, 6, "foobar":utf8, 6, "bazqux":utf8, 0xfc,
    1_713_824_559_637:little-size(64), 0x00, 3, "foo":utf8, 3, "bar":utf8, 0xfd,
    1_714_089_298:little-size(32), 0x00, 3, "baz":utf8, 3, "qux":utf8, 0xff,
    0x893bb74ef80f7719:size(64),
  >>
  let table = [#("foobar", "bazqux"), #("foo", "bar"), #("baz", "qux")]

  rdb.parse(input) |> should.equal(Ok(table))
}

pub fn parse_2_test() {
  let assert Ok(input) =
    "524544495330303131fa0a72656469732d62697473c040fa0972656469732d76657205372e322e30fe00fb01000009726173706265727279066f72616e6765fff085253910dc35eb0a"
    |> bit_array.base16_decode

  let table = [#("raspberry", "orange")]
  rdb.parse(input) |> should.equal(Ok(table))
}
