import redis/types.{type RedisType, Array, BulkString, SimpleString}

pub type RedisCommand {
  Ping
}

pub fn parse(input: RedisType) -> Result(RedisCommand, String) {
  case input {
    Array([BulkString("PING")]) -> Ok(Ping)
    _ -> Error("unknown command")
  }
}

pub fn process(command: RedisCommand) -> RedisType {
  case command {
    Ping -> SimpleString("PONG")
  }
}
