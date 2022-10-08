// Derived from http://stupidpythonideas.blogspot.com/2013/05/sockets-are-byte-streams-not-message.html
// and then translated from https://github.com/Erhannis/zeroconnect/blob/master/zeroconnect/message_socket.py
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:sync/sync.dart';

import 'Channel.dart';

Uint8List uint64BigEndianBytes(int value) => Uint8List(8)..buffer.asByteData().setUint64(0, value, Endian.big);
int bigEndianBytesUint64(Uint8List bytes) => bytes.buffer.asByteData().getUint64(0, Endian.big);

/**
    Packages data from a stream into messages, by wrapping messages with a prefixed length.<br/>
    Note: I've added locks on sending and receiving, so message integrity should be safe, but you should
    still be aware of the potential confusion/mixups inherent to having multiple threads communicate over
    a single channel.
 */
class MessageSocket {
    Socket _sock;
    Mutex _sendLock;
    Mutex _recvLock;

    late final ChannelIn<Uint8List?> _rxIn;
    late final ChannelOut<int> _recvCountOut;

    MessageSocket(this._sock): this._sendLock = Mutex(), this._recvLock = Mutex() {
        var _rxChannel = Channel<Uint8List?>();
        this._rxIn = _rxChannel.getIn();
        var rxOut = _rxChannel.getOut();

        var _recvCountChannel = Channel<int>();
        var _recvCountIn = _recvCountChannel.getIn();
        this._recvCountOut = _recvCountChannel.getOut();

        unawaited(Future(() async {
            //DO I don't think this handles socket closure
            var pending = BytesBuilder();
            var requested = 0;
            await for (var data in _sock) { //TODO I'm pretty sure data will still accumulate in the Socket; I wish I could backpressure it
                pending.add(data);
                if (requested == 0) {
                    requested = await _recvCountIn.read();
                }
                if (pending.length >= requested) {
                    var temp = pending.takeBytes();
                    await rxOut.write(Uint8List.fromList(temp.getRange(0, requested).toList())); //TODO This seems like a lot of conversions
                    pending.add(temp.getRange(requested, temp.length).toList());
                    requested = 0;
                }
            }
        }));
    }

    /**
     * Send a message.
     * `data` should be a list of bytes, or a string (which will then be encoded with utf-8.)
     * Throws exception on socket failure.
     */
    Future<void> sendMsg(Uint8List data) async {
        //TODO Also accept string
        await _sendLock.acquire();
        try {
            _sock.add(uint64BigEndianBytes(data.length));
            // Send inverse, for validation? ...I THINK we can trust TCP to guarantee ordering and whatnot
            _sock.add(data);
        } finally {
            _sendLock.release();
        }
    }

    /**
     * See `sendMsg`
     */
    Future<void> sendString(String s) async {
        await sendMsg(Uint8List.fromList(s.codeUnits)); //TODO UTF-16???
    }

    /**
     * Result of [] simply means an empty message; result of null implies some kind of failure; likely a disconnect.
     */
    Future<Uint8List?> recvMsg() async {
        await _recvLock.acquire();
        try {
            await _recvCountOut.write(8);
            var lengthbuf = await _rxIn.read();
            if (lengthbuf == null) {
                return null;
            }
            var length = bigEndianBytesUint64(lengthbuf);
            if (length == 0) {
                return Uint8List(0);
            } else {
                await _recvCountOut.write(length);
                return await _rxIn.read();
            }
        } finally {
            _recvLock.release();
        }
    }

    Future<void> close() async {
        await _sock.close();
    }
}