// Derived from http://stupidpythonideas.blogspot.com/2013/05/sockets-are-byte-streams-not-message.html
// and then translated from https://github.com/Erhannis/zeroconnect/blob/master/zeroconnect/message_socket.py
import 'dart:io';

import 'package:sync/sync.dart';

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

    MessageSocket(this._sock): this._sendLock = Mutex(), this._recvLock = Mutex();

    Future<void> sendMsg(List<int> data) async {

    }

    Future<void> recvMsg() async {
        _sock.
    }

    def sendMsg(self, data):
        """
        Send a message.
        `data` should be a list of bytes, or a string (which will then be encoded with utf-8.)
        Throws exception on socket failure.
        """
        if type(data) == str:
            data = data.encode("utf-8")
        length = len(data)
        self.sendLock.acquire()
        try:
            self.sock.sendall(struct.pack('!Q', length))
            # Send inverse, for validation? ...I THINK we can trust TCP to guarantee ordering and whatnot
            self.sock.sendall(data)
        finally:
            self.sendLock.release()
            pass

    def recvMsg(self): #TODO readLock?
        """
        Result of [] simply means an empty message; result of None implies some kind of failure; likely a disconnect.
        """
        self.recvLock.acquire()
        try:
            lengthbuf = recvall(self.sock, 8)
            if lengthbuf == None:
                return None
            length, = struct.unpack('!Q', lengthbuf)
            #print(f"RM len {length}")
            if length == 0:
                return b""
            else:
                return recvall(self.sock, length)
        finally:
            self.recvLock.release()
            pass

    def close(self):
        self.sock.close()

    #TODO Any other socket functions?

def recvall(sock, count):
    buf = b''
    while count:
        newbuf = sock.recv(count)
        if not newbuf: return None
        buf += newbuf
        count -= len(newbuf)
    return buf
}