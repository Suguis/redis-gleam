import resp

pub type CommandError {
  Invalid(cmd: String)
  Malformed
}

pub fn to_string(err: CommandError) -> String {
  case err {
    Invalid(cmd) -> "invalid command: " <> cmd
    Malformed -> "malformed request received"
  }
  |> resp.BulkString
  |> resp.to_string
}
