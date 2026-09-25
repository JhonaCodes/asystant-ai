/// Visible lifecycle phases of a chat turn, including permission and error states.
enum ChatPhase {
  idle,
  initializing,
  ready,
  thinking,
  executing,
  permission,
  done,
  canceled,
  error,
}
