.data
w: .string "w"
a: .string "a"
s: .string "s"
d: .string "d"
q: .string "q"
bomba: .string "kabum!"
tiroc: .string "piu piu cima"
tirob: .string "piu piu baixo"
tiroe: .string "piu piu esquerda"
tirod: .string "piu piu direita"
menu: .string "menu open"

.text
li s2, 200
li s3, 200

srli s4, s2, 1      # y do jogador
srli s5, s3, 1      # x do jogador

la t0, a
lb s6, 0(t0)
la t0, d
lb s7, 0(t0)
la t0, w
lb s8, 0(t0)
la t0, s
lb s9, 0(t0)
la t0, q
lb s10, 0(t0)

li t0, 0xff200000   # base do KDMMIO

WHILE:

wait_key:
    lw t3, 0(t0)        # controle
    andi t3, t3, 1      # bit de tecla pronta
    beqz t3, wait_key

    lw s1, 4(t0)        # dado: tecla lida

    beq s1, s6, AKEY
    beq s1, s7, DKEY
    beq s1, s8, WKEY
    beq s1, s9, SKEY
    beq s1, s10, QKEY

    li t4, 'i'
    beq s1, t4, IKEY
    li t4, 'k'
    beq s1, t4, KKEY
    li t4, 'j'
    beq s1, t4, JKEY
    li t4, 'l'
    beq s1, t4, LKEY

    li t4, 27           # ESC = 27 em ASCII
    beq s1, t4, ESCKEY

    j WHILE             # tecla desconhecida: ignora

AKEY:
    addi s5, s5, -1
    j PRINT
DKEY:
    addi s5, s5, 1
    j PRINT
WKEY:
    addi s4, s4, 1
    j PRINT
SKEY:
    addi s4, s4, -1
    j PRINT

QKEY:
    la a0, bomba
    j MSG

IKEY:
    la a0, tiroc
    j MSG
KKEY:
    la a0, tirob
    j MSG
JKEY:
    la a0, tiroe
    j MSG
LKEY:
    la a0, tirod
    j MSG

ESCKEY:
    la a0, menu
    j MSG

MSG:
    li a7, 4            # imprime a string que está em a0
    ecall
    li a7, 11
    li a0, 10
    ecall
    j WHILE

PRINT:
    li a7, 1
    mv a0, s5           # imprime x
    ecall
    li a7, 11
    li a0, 10
    ecall

    li a7, 1
    mv a0, s4           # imprime y
    ecall
    li a7, 11
    li a0, 10
    ecall

    j WHILE
