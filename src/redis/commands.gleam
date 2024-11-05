import redis/types.{type RedisType}

pub type RedisCommand {
  Ping
}

pub fn parse(input: RedisType) -> Result(RedisCommand, String) {
  case input {
    types.SimpleString("PING") -> Ok(Ping)
    _ -> Error("unknown command")
  }
}

pub fn process(command: RedisCommand) -> RedisType {
  case command {
    Ping -> types.SimpleString("PONG")
  }
}
