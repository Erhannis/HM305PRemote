import 'package:hm305p_remote/Exchanger.dart';
import 'package:sync/mutex.dart';

class Channel<T> implements ChannelIn<T>, ChannelOut<T> {
  final _ex = Exchanger<T?>();
  final _readLock = Mutex();
  final _writeLock = Mutex();

  List<String> _writers = [];
  List<String> _readers = [];

  Future<T> read(String tag) async {
    await _readLock.acquire();
    try {
      _readers.add(tag);
      dynamic x = (await _ex.exchange(tag, null));
      return x;
    } finally {
      _readers.remove(tag);
      _readLock.release();
    }
  }

  Future<void> write(String tag, T x) async {
    await _writeLock.acquire();
    try {
      _writers.add(tag);
      await _ex.exchange(tag, x);
    } finally {
      _writers.remove(tag);
      _writeLock.release();
    }
  }

  ChannelIn<T> getIn() {
    return this;
  }

  ChannelOut<T> getOut() {
    return this;
  }
}

abstract class ChannelIn<T> {
  Future<T> read(String tag);
}

abstract class ChannelOut<T> {
  Future<void> write(String tag, T x);
}