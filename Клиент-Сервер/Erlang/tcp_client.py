# tcp_client.py
import socket

HOST = '127.0.0.1'
PORT = 5555

with socket.create_connection((HOST, PORT)) as s:
    print(f"Connected to {HOST}:{PORT}. Type lines and Enter. Empty line to quit.")
    while True:
        line = input("> ")
        if line == "":
            break
        s.sendall((line + "\n").encode())
        data = s.recv(4096)
        # сервер отправляет одну или две строки (echo + возможно RESULT)
        print(data.decode(), end='')
