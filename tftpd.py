#!/usr/bin/env python
import socket

UDP_PORT = 69

# Open socket
sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM) # UDP
sock.bind(("", UDP_PORT))

# Infinite loop waiting for requests
while True:
    data, client = sock.recvfrom(1500)
    opcode = (data[0] << 8) | data[1]

    if opcode == 1:  # RRQ
       file_name = data[2:].split(b'\0')[0]
       print file_name
       file_handle = open(file_name, 'rb')  # Open file for reading
       block = 1

       # Generate response
       data = file_handle.read(512)
       response = chr(0) + chr(3) + chr(0) + chr(1) + data
       sock.sendto(response, client)

    if opcode == 2:  # WRQ
       pass

    if opcode == 3:  # DATA
       pass

    if opcode == 4:  # ACK
       block = (data[2] << 8) | data[3]
       file_handle.seek(block*512)
       data = file_handle.read(512)
       response = chr(0) + chr(3) + chr(block >> 8) + chr(block & 0xff) + data
       sock.sendto(response, client)
       pass

    if opcode == 5:  # ERROR
       pass


