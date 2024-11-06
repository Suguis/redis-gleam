import gleam/string
import redis/types.{type RespType, Array, BulkString, SimpleString}

pub type RedisCommand {
  Ping
  Echo(String)
}

pub fn parse(input: RespType) -> Result(RedisCommand, String) {
  case input {
    Array([BulkString(cmd), ..args]) ->
      case string.lowercase(cmd), args {
        "echo", [BulkString(str)] -> Ok(Echo(str))
        "ping", _ -> Ok(Ping)
        cmd, _ -> Error("invalid command: " <> cmd)
      }
    _ -> Error("command must be inside array")
  }
}

pub fn process(command: RedisCommand) -> RespType {
  case command {
    Ping -> SimpleString("PONG")
    Echo(str) -> BulkString(str)
  }
}
