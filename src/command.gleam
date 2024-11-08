import carpenter/table
import command_error.{type CommandError, Invalid, Malformed}
import gleam/bool
import gleam/erlang/process
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/otp/task
import gleam/pair
import gleam/result
import gleam/string
import resp.{type RespType, Array, BulkString, Null, SimpleString}

pub type RedisCommand {
  Ping
  Echo(String)
  Get(String)
  Set(key: String, value: String, px: Option(Int))
}

const set_args_definition = [#("px", 1)]

pub fn parse(input: RespType) -> Result(RedisCommand, CommandError) {
  case input {
    Array([BulkString(cmd), ..args]) ->
      case string.lowercase(cmd), args {
        "echo", [BulkString(str)] -> Ok(Echo(str))
        "ping", _ -> Ok(Ping)
        "get", [BulkString(key)] -> Ok(Get(key))
        "set", [BulkString(key), BulkString(val), ..args] -> {
          use args <- result.try(parse_args(args, set_args_definition))
          use px <- result.try(
            list.find(args, fn(pair) { pair.0 == "px" })
            |> result.map(fn(pair) { pair |> pair.second |> list.first })
            |> result.flatten
            |> option.from_result
            |> option.map(int.parse)
            |> fn(x) {
              case x {
                None -> Ok(None)
                Some(Ok(val)) -> Ok(Some(val))
                Some(Error(_)) -> Error(Invalid("set"))
              }
            },
          )
          Ok(Set(key, val, px: px))
        }
        cmd, _ -> Error(Invalid(cmd))
      }
    _ -> Error(Malformed)
  }
}

fn parse_args(
  args: List(RespType),
  definition: List(#(String, Int)),
) -> Result(List(#(String, List(String))), CommandError) {
  parse_args_loop(args, definition, [])
}

fn parse_args_loop(
  args: List(RespType),
  definition: List(#(String, Int)),
  result: List(#(String, List(String))),
) -> Result(List(#(String, List(String))), CommandError) {
  case args {
    [] -> Ok(result)
    [BulkString(arg), ..rest] -> {
      let arg = string.lowercase(arg)
      use #(_, n) <- result.try(
        list.find(definition, fn(pair) { pair.0 == arg })
        |> result.replace_error(Invalid(arg)),
      )
      use <- bool.guard(list.length(rest) < n, Error(Invalid(arg)))
      let #(args, rest) = list.split(rest, n)
      use args <- result.try(
        list.map(args, fn(arg) {
          case arg {
            BulkString(arg) -> Ok(arg)
            _ -> Error(Malformed)
          }
        })
        |> result.all,
      )
      parse_args_loop(rest, definition, [#(arg, args), ..result])
    }
    _ -> Error(Malformed)
  }
}

pub fn process(
  command: RedisCommand,
  table: table.Set(String, String),
) -> RespType {
  case command {
    Ping -> SimpleString("PONG")
    Echo(str) -> BulkString(str)
    Get(key) ->
      case table |> table.lookup(key) {
        [] -> Null
        [#(_, val)] -> BulkString(val)
        _ -> panic as "unreachable"
      }
    Set(key, val, None) -> {
      table.insert(table, [#(key, val)])
      SimpleString("OK")
    }
    Set(key, val, px: Some(px)) -> {
      table.insert(table, [#(key, val)])
      task.async(fn() {
        process.sleep(px)
        table.delete(table, key)
      })
      SimpleString("OK")
    }
  }
}
