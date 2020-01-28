10 REM THIS PROGRAM TESTS THE YM2151 SOUND CHIP

80 GOSUB 2000
90 SO=TI
100 READ NO, DU
105 PRINT "NO=";NO,"DU=";DU
110 SO=SO+DU*12
120 POKE $9FE0, $08: POKE $9FE1, $00: REM KEY OFF
130 IF NO=0 THEN GOTO 170
140 IF NO=$FF THEN END
150 POKE $9FE0, $28: POKE $9FE1, NO:  REM KEY CODE
160 POKE $9FE0, $08: POKE $9FE1, $08: REM KEY ON
170 IF TI<SO THEN GOTO 170
180 GOTO 100

1999 REM CONFIGURE CHANNEL 0
2000 POKE $9FE0, $80: POKE $9FE1, $1F: REM CHANNEL 0 MODULATOR 1 ATTACK RATE
2005 POKE $9FE0, $A0: POKE $9FE1, $0B: REM CHANNEL 0 MODULATOR 1 DECAY RATE
2010 POKE $9FE0, $E0: POKE $9FE1, $FF: REM CHANNEL 0 MODULATOR 1 RELEASE RATE
2020 POKE $9FE0, $20: POKE $9FE1, $DF: REM CHANNEL 0 CONTROL
2030 RETURN

3010 DATA $51, 1: REM D

3100 DATA $4A, 2: REM A
3110 DATA $51, 2: REM D
3120 DATA $51, 3: REM D
3130 DATA $54, 1: REM E

3200 DATA $55, 2: REM F
3210 DATA $51, 2: REM D
3220 DATA $51, 3: REM D
3230 DATA $55, 1: REM F

3300 DATA $54, 2: REM E
3310 DATA $4E, 2: REM C
3320 DATA $4E, 3: REM C
3330 DATA $54, 1: REM E

3400 DATA $55, 2: REM F
3410 DATA $51, 2: REM D
3420 DATA $51, 3: REM D
3430 DATA $51, 1: REM D

3500 DATA $4A, 2: REM A
3510 DATA $51, 2: REM D
3520 DATA $51, 3: REM D
3530 DATA $54, 1: REM E

3600 DATA $55, 2: REM F
3610 DATA $51, 2: REM D
3620 DATA $51, 3: REM D
3630 DATA $55, 1: REM F

3700 DATA $5A, 2: REM A
3710 DATA $58, 2: REM G
3720 DATA $55, 2: REM F
3730 DATA $54, 2: REM E

3800 DATA $55, 2: REM F
3810 DATA $51, 2: REM D
3820 DATA $51, 3: REM D
3830 DATA $51, 1: REM D

4000 DATA $5A, 2: REM A
4010 DATA $5A, 2: REM A
4020 DATA $58, 2: REM G
4030 DATA $55, 2: REM F

4100 DATA $58, 2: REM G
4110 DATA $54, 2: REM E
4120 DATA $54, 3: REM E
4130 DATA $54, 1: REM E

4200 DATA $58, 2: REM G
4210 DATA $58, 2: REM G
4220 DATA $55, 2: REM F
4230 DATA $54, 2: REM E

4300 DATA $55, 2: REM F
4310 DATA $51, 2: REM D
4320 DATA $51, 3: REM D
4330 DATA $51, 1: REM D

4400 DATA $5A, 2: REM A
4410 DATA $5A, 2: REM A
4420 DATA $58, 2: REM G
4430 DATA $55, 2: REM F

4500 DATA $58, 2: REM G
4510 DATA $54, 2: REM E
4520 DATA $54, 3: REM E
4530 DATA $54, 1: REM E

4600 DATA $58, 1: REM G
4605 DATA $58, 1: REM G
4610 DATA $58, 2: REM G
4620 DATA $55, 2: REM F
4630 DATA $54, 2: REM E

4700 DATA $55, 2: REM F
4710 DATA $51, 2: REM D
4720 DATA $51, 3: REM D
4730 DATA $00, 1: REM -

9999 DATA $FF, 1: REM END

