Future<void> sleep(int ms) async {
  await Future.delayed(Duration(milliseconds: ms));
}

extension SWLap on Stopwatch {
  /**
   * Returns the elapsed time, then resets the stopwatch.
   */
  Duration lap() {
    var e = this.elapsed;
    this.reset();
    return e;
  }
}