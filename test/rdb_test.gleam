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
