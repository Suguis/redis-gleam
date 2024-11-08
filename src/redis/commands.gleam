import carpenter/table
import gleam/string
import redis/types.{type RespType, Array, BulkString, Null, SimpleString}

pub type RedisCommand {
  Ping
  Echo(String)
  Get(String)
  Set(String, String)
}

pub fn parse(input: RespType) -> Result(RedisCommand, String) {
  case input {
    Array([BulkString(cmd), ..args]) ->
      case string.lowercase(cmd), args {
        "echo", [BulkString(str)] -> Ok(Echo(str))
        "ping", _ -> Ok(Ping)
        "get", [BulkString(key)] -> Ok(Get(key))
        "set", [BulkString(key), BulkString(val)] -> Ok(Set(key, val))
        cmd, _ -> Error("invalid command: " <> cmd)
      }
    _ -> Error("command must be inside array")
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
    Set(key, val) -> {
      table.insert(table, [#(key, val)])
      SimpleString("OK")
    }
  }
}
