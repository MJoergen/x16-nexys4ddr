#!/usr/bin/env python
import socket

UDP_PORT = 69

TFTP_RRQ   = 1
TFTP_WRQ   = 2
TFTP_DATA  = 3
TFTP_ACK   = 4
TFTP_ERROR = 5

# Open socket
sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM) # UDP
sock.bind(("", UDP_PORT))

# Infinite loop waiting for requests
while True:
    data, client = sock.recvfrom(1500)
    opcode = (data[0] << 8) | data[1]

    if opcode == TFTP_RRQ:
       file_name = data[2:].split(b'\0')[0]
       print file_name
       file_handle = open(file_name, 'rb')  # Open file for reading
       block = 1

       # Generate response
       data = file_handle.read(512)
       response = chr(0) + chr(TFTP_DATA) + chr(0) + chr(1) + data
       sock.sendto(response, client)

    if opcode == TFTP_WRQ:
       file_name = data[2:].split(b'\0')[0]
       print file_name
       file_handle = open(file_name, 'wb')  # Open file for reading

       # Generate response
       response = chr(0) + chr(TFTP_ACK) + chr(0) + chr(0)
       sock.sendto(response, client)

    if opcode == TFTP_DATA:
       block = (data[2] << 8) | data[3]
       file_handle.seek(block*512)
       file_handle.write(data[4:])

       # Generate response
       response = chr(0) + chr(TFTP_ACK) + chr(block >> 8) + chr(block & 0xff)
       sock.sendto(response, client)

    if opcode == TFTP_ACK:
       block = (data[2] << 8) | data[3]

       # Generate response
       file_handle.seek(block*512)
       data = file_handle.read(512)
       block += 1
       response = chr(0) + chr(3) + chr(block >> 8) + chr(block & 0xff) + data
       sock.sendto(response, client)
       pass

    if opcode == TFTP_ERROR:
       # Just ignore
       pass


