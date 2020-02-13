#!/usr/bin/env python

import sys
import pathlib

tokens = [ 
    "EBD"   , "FOR"   , "NEXT"  , "DATA"  , "VPOKE" , "INPUT" , "DIM"   , "READ"  , 
    "LET"   , "GOTO"  , "RUN"   , "IF"    , "RESTOR", "GOSUB" , "RETURN", "VPEEK" , 

    "STOP"  , "ON"    , "WAIT"  , "LOAD"  , "SAVE"  , "VERIFY", "DEF"   , "POKE"  , 
    "PRINT#", "PRINT" , "CONT"  , "LIST"  , "CLS"   , "CMD"   , "SYS"   , "OPEN"  , 

    "CLOSE" , "GET"   , "NEW"   , "TAB("  , "TO"    , "FN"    , "SPC("  , "THEN"  , 
    "NOT"   , "STEP"  , "+"     , "-"     , "*"     , "/"     , "???"   , "AND"   , 

    "OR"    , ">"     , "="     , "<"     , "SGN"   , "INT"   , "ABS"   , "USR"   , 
    "FRE"   , "POS"   , "SQR"   , "RND"   , "LOG"   , "EXP"   , "COS"   , "SIN"   , 

    "TAN"   , "ATN"   , "PEEK"  , "LEN"   , "STR$"  , "VAL"   , "ASC"   , "CHR$"  , 
    "LEFT$" , "RIGHT$", "MID$"  , "GO"    ,
    ]

if len(sys.argv) < 2:
    sys.exit(-1)

file_name = sys.argv[1]

state = 0
ptr   = 0x0801
addr  = 0

for byte in pathlib.Path(file_name).read_bytes():
    if state == 0:
        if byte != 1:
            print("ERROR");
        state = 1
    elif state == 1:
        if byte != 8:
            print("ERROR");
        addr = 0x0800
        state = 2
    elif state == 2:
        if addr != ptr:
            print("ERROR");
        ptr = byte
        state = 3
    elif state == 3:
        ptr = ptr + (byte << 8)
        state = 4
    elif state == 4:
        val = byte
        state = 5
    elif state == 5:
        val = val + (byte << 8)
        print(val, end='')
        print(' ', end='')
        state = 6
    elif state == 6:
        if byte == 0:
            print()
            state = 2
        elif byte < 0x80:
            print(chr(byte), end='')
        elif byte >= 0x80 and byte <= 0xcb:
            print(tokens[byte-0x80], end='')
    addr += 1

