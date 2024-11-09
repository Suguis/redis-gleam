import bravo/uset
import command_error.{type CommandError, Invalid, Malformed}
import gleam/erlang/process
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/otp/task
import gleam/result
import gleam/string
import resp.{type RespType, Array, BulkString, Null, SimpleString}

pub type RedisCommand {
  Ping
  Echo(String)
  Get(String)
  Set(key: String, value: String, args: SetArgs)
  ConfigGet(String)
  Keys
}

pub type SetArgs {
  SetArgs(px: Option(Int))
}

pub fn parse(input: RespType) -> Result(RedisCommand, CommandError) {
  case input {
    Array([BulkString(cmd), ..args]) ->
      case string.lowercase(cmd), args {
        "echo", [BulkString(str)] -> Ok(Echo(str))
        "ping", _ -> Ok(Ping)
        "get", [BulkString(key)] -> Ok(Get(key))
        "set", [BulkString(key), BulkString(val), ..args] -> {
          use args <- result.try(parse_set_args(args))
          Ok(Set(key, val, args))
        }
        "config", [BulkString(cmd), ..args] -> {
          case string.lowercase(cmd), args {
            "get", [BulkString(str)] -> Ok(ConfigGet(str))
            cmd, _ -> Error(Invalid("config " <> cmd))
          }
        }
        "keys", [BulkString("*")] -> Ok(Keys)
        cmd, _ -> Error(Invalid(cmd))
      }
    _ -> Error(Malformed)
  }
}

fn parse_set_args(args: List(RespType)) -> Result(SetArgs, CommandError) {
  case args {
    [] -> Ok(SetArgs(None))
    [BulkString(arg), ..rest] -> {
      case string.lowercase(arg), rest {
        "px", [BulkString(px)] -> {
          use px <- result.try(
            int.parse(px) |> result.replace_error(Invalid("set px " <> px)),
          )
          Ok(SetArgs(px: Some(px)))
        }
        arg, _ -> Error(Invalid("set " <> arg))
      }
    }
    _ -> Error(Invalid("set"))
  }
}

pub fn process(
  command: RedisCommand,
  store_table store_table: uset.USet(#(String, String)),
  config_table config_table: uset.USet(#(String, String)),
) -> RespType {
  case command {
    Ping -> SimpleString("PONG")
    Echo(str) -> BulkString(str)
    Get(key) ->
      case store_table |> uset.lookup(key) {
        Error(_) -> Null
        Ok(#(_, val)) -> BulkString(val)
      }
    Set(key, val, SetArgs(px: None)) -> {
      uset.insert(store_table, [#(key, val)])
      SimpleString("OK")
    }
    Set(key, val, SetArgs(px: Some(px))) -> {
      uset.insert(store_table, [#(key, val)])
      task.async(fn() {
        process.sleep(px)
        uset.delete_key(store_table, key)
      })
      SimpleString("OK")
    }
    ConfigGet(key) ->
      case config_table |> uset.lookup(key) {
        Error(_) -> Array([])
        Ok(#(key, val)) -> Array([BulkString(key), BulkString(val)])
      }
    Keys ->
      uset.tab2list(store_table)
      |> list.map(fn(k) { BulkString(k.0) })
      |> Array
  }
}
