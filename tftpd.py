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

# State information
file_handle = None

def build_dir(file_list):
   data = b'\x01\x08'
   addr = 0x0801
   for file_name in file_list:
      file_size = os.stat(file_name).st_size / 256
      next_addr = addr + 32
      data += chr(next_addr & 0xff) + chr(next_addr >> 8)
      data += chr(file_size & 0xff) + chr(file_size >> 8)
      data += "{:<27}".format(file_name[:27]) # Truncate/pad file name
      data += b'\x00'
      addr = next_addr
   data += b'\x00\x00'


# Infinite loop waiting for requests
while True:
    data, client = sock.recvfrom(1500)
    opcode = (ord(data[0]) << 8) | ord(data[1])

    if opcode == TFTP_RRQ:
       file_name = data[2:].split(b'\0')[0]
       print 'LOAD ' + file_name + ' ...',
       if file_name == '$':
          os.remove('$')
          file_list = os.listdir('.')
          data = build_dir(file_list)
          file_handle = open('$', 'wb')  # Open file for reading
          file_handle.write(data)
          file_handle.close()

       file_handle = open(file_name, 'rb')  # Open file for reading
       block = 1

       # Generate response
       data = file_handle.read(512)
       response = chr(0) + chr(TFTP_DATA) + chr(0) + chr(1) + data
       sock.sendto(response, client)

    if opcode == TFTP_WRQ:
       file_name = data[2:].split(b'\0')[0]
       print 'SAVE ' + file_name + ' ...',
       file_handle = open(file_name, 'wb')  # Open file for reading

       # Generate response
       response = chr(0) + chr(TFTP_ACK) + chr(0) + chr(0)
       sock.sendto(response, client)

    if opcode == TFTP_DATA and file_handle is not None:
       block = (ord(data[2]) << 8) | ord(data[3])
       file_handle.seek((block-1)*512)
       file_handle.write(data[4:])

       # Generate response
       response = chr(0) + chr(TFTP_ACK) + chr(block >> 8) + chr(block & 0xff)
       sock.sendto(response, client)

       if len(data)-4 < 512:
           print "DONE."
           file_handle.close()
           file_handle = None

    if opcode == TFTP_ACK and file_handle is not None:
       block = (ord(data[2]) << 8) | ord(data[3])

       # Generate response
       file_handle.seek(block*512)
       data = file_handle.read(512)
       block += 1
       response = chr(0) + chr(3) + chr(block >> 8) + chr(block & 0xff) + data
       sock.sendto(response, client)
       if len(data) < 512:
           print "DONE."
           file_handle = None
       pass

    if opcode == TFTP_ERROR:
       # Just ignore
       pass


