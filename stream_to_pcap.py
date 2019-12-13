#!/usr/bin/env python3

output_file_name = 'video.pcap'
output_file_handle = open(output_file_name, 'wb')  # Open file for writing


# Process a chunk of 8 rows
def process_chunk(data):
   assert len(data) == 160*8*4

# Processes a single image
# Each image is 160x130 with 4 bytes pr pixel
# Each image is processed 8 rows at a time. Only the first 120 rows are used.
def process_image(data):
   assert len(data) == 160*130*4
   for chunk in range(15):
      process_chunk(data[160*8*chunk*4:160*8*(chunk+1)*4])


dir_name = '/home/mfj/Downloads/axelf-160x120'

frame_rate = 23.976024
frame_time = 1.0 / frame_rate

file_number = 11
while True:
   # File names are of the form 'scene00001.bmp'
   file_name = 'scene{:05d}.bmp'.format(file_number)
   print(file_name)

   # Read file header
   file_handle = open(dir_name+'/'+file_name, 'rb')  # Open file for reading
   data = file_handle.read(83254)   # 160x130x4

   # Verify integrity of file header
   assert data[0] == 0x42 #B
   assert data[1] == 0x4D #M

   # Verify file size
   assert int.from_bytes(data[2:6], byteorder='little') == 0x014536

   # Get offset of bitmap
   assert int.from_bytes(data[10:14], byteorder='little') == 0x36

   # Verify length of DIB header
   assert int.from_bytes(data[14:18], byteorder='little') == 0x28

   # Verify image size
   assert int.from_bytes(data[18:22], byteorder='little') == 160
   assert int.from_bytes(data[22:26], byteorder='little') == 130

   # Verify number of colour planes
   assert int.from_bytes(data[26:28], byteorder='little') == 1

   # Verify colour depth
   assert int.from_bytes(data[28:30], byteorder='little') == 32

   # Verify no compression
   assert int.from_bytes(data[30:34], byteorder='little') == 0

   # Verify image size
   assert int.from_bytes(data[34:38], byteorder='little') == 0x014500

   process_image(data[54:])

   file_handle.close()

   # Prepare for next image
   file_number += 1

