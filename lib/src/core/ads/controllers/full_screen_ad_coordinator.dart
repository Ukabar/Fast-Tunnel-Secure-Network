class FullScreenAdCoordinator {
  var _active = false;

  bool get isActive => _active;

  bool acquire() {
    if (_active) return false;
    _active = true;
    return true;
  }

  void release() {
    _active = false;
  }
}
