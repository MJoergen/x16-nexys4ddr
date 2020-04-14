# TODO

## VERA:
* Check read from VERA (both config and VRAM and Palette and Sprite
  attributes).
* Verify SD-card.
* Implement RESET in CTRL register.
* Implement IRQ\_LINE.
* Implement sprites. This requires making a budget of the VRAM bandwidth, and
  possibly increasing the data width to 32 bytes. Additionally, generate a
  complete scan line at a time, rather than a single pixel at a time. In other
  words, a complete rewrite :-)

## YM2151
* Add support for feedback register.
* Add support for all four devices on each channel.

## ROM
* Fix some apparent bugs in the Ethernet code, regarding timeout handling.

# DONE

* Update the X16-ROM to release R37. This will require rewriting the VERA
  module, as well as updating the Ethernet part of the ROM.
