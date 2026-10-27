
.text
# ---------- pinta o mapa todo de escuro ----------
li a0, 0x49494949

jal  gp,DRAW0

# ---------- posição inicial do personagem ----------
li s5, 156              # x
li s4, 116              # y

mv a0, s5
mv a1, s4
li a2, 0xff             # cor clara (branco)
jal DRAW

# ---------- loop principal ----------
WHILE:
    jal KEY2            # key2 do lamar
    #local
    beqz s1, WHILE      # se tecla igual a zero jump para o while (aqui eh possivel colocar outras chamadas de funcao e outros processamentos)

    li t4, 27           # ESC codigos asc2 do esc eh 27
    beq s1, t4, MENU

    li s6, 0            # dx
    li s7, 0            # dy

    li t4, 'w'
    beq s1, t4, KW
    li t4, 's'
    beq s1, t4, KS
    li t4, 'a'
    beq s1, t4, KA
    li t4, 'd'
    beq s1, t4, KD
    j WHILE             # tecla desconhecida: ignora

KW: li s7, -4
    j MOVE
KS: li s7, 4
    j MOVE
KA: li s6, -4
    j MOVE
KD: li s6, 4
    j MOVE

MOVE:
    # apaga na posição antiga (pinta de escuro)
    mv a0, s5
    mv a1, s4
    li a2, 0x49
    jal DRAW

    # atualiza posição
    add s5, s5, s6
    add s4, s4, s7

    # limites: x em [0,312], y em [0,232]
    bgez s5, X_OK1
    li s5, 0
X_OK1:
    li t4, 312
    ble s5, t4, X_OK2
    li s5, 312
X_OK2:
    bgez s4, Y_OK1
    li s4, 0
Y_OK1:
    li t4, 232
    ble s4, t4, Y_OK2
    li s4, 232
Y_OK2:

    # desenha na posição nova (cor clara)
    mv a0, s5
    mv a1, s4
    li a2, 0xff
    jal DRAW

    j WHILE

# =====================================================
#                       MENU
# s0 = opção selecionada (0 = VOLTAR, 1 = CONFIG)
# =====================================================
MENU:
    li s0, 0
    jal DRAW_MENU

MENU_LOOP:
    jal KEY2
    beqz s1, MENU_LOOP

    li t4, 27           # ESC: volta ao jogo
    beq s1, t4, MENU_BACK
    li t4, 'w'
    beq s1, t4, MENU_UP
    li t4, 's'
    beq s1, t4, MENU_DOWN
    li t4, 10           # Enter (LF)
    beq s1, t4, MENU_OK
    li t4, 13           # Enter (CR)
    beq s1, t4, MENU_OK
    j MENU_LOOP

MENU_UP:
    li s0, 0
    jal DRAW_MENU
    j MENU_LOOP

MENU_DOWN:
    li s0, 1
    jal DRAW_MENU
    j MENU_LOOP

MENU_OK:
    beqz s0, MENU_BACK  # VOLTAR
    # CONFIG: ainda não implementado
    j MENU_LOOP

MENU_BACK:
    li a0, 0x49494949   # redesenha o mapa
    jal FILL_SCREEN
    mv a0, s5           # e o personagem
    mv a1, s4
    li a2, 0xff
    jal DRAW
    j WHILE

# ---------- DRAW_MENU: desenha o menu conforme s0 ----------
DRAW_MENU:
    addi sp, sp, -4
    sw ra, 0(sp)

    li a0, 0            # fundo preto
    jal FILL_SCREEN

    # opção 0: VOLTAR
    li a2, 0x92         # cinza (não selecionada)
    bnez s0, O0_COR
    li a2, 0xFC         # amarelo (selecionada)
O0_COR:
    li a0, 100
    li a1, 90
    la a3, STR_VOLTAR
    jal DRAW_TEXT
    bnez s0, M0_SKIP
    li a0, 80           # marcador
    li a1, 94
    li a2, 0xFC
    jal DRAW
M0_SKIP:

    # opção 1: CONFIG
    li a2, 0x92
    beqz s0, O1_COR
    li a2, 0xFC
O1_COR:
    li a0, 100
    li a1, 130
    la a3, STR_CONFIG
    jal DRAW_TEXT
    beqz s0, M1_SKIP
    li a0, 80           # marcador
    li a1, 134
    li a2, 0xFC
    jal DRAW
M1_SKIP:

    lw ra, 0(sp)
    addi sp, sp, 4
    ret

# ---------- FILL_SCREEN: a0 = 4 pixels de cor (word) ----------
FILL_SCREEN:
    li t0, 0xff000000
    li t1, 0xff012c00
FS_LOOP:
    sw a0, 0(t0)
    addi t0, t0, 4
    bltu t0, t1, FS_LOOP
    ret

# ---------- DRAW_TEXT: a0=x, a1=y, a2=cor, a3=string (índices, termina com -1) ----------
DRAW_TEXT:
    addi sp, sp, -20
    sw ra, 0(sp)
    sw s8, 4(sp)
    sw s9, 8(sp)
    sw s10, 12(sp)
    sw s11, 16(sp)
    mv s8, a0
    mv s9, a1
    mv s10, a2
    mv s11, a3
T_LOOP:
    lb t0, 0(s11)
    bltz t0, T_END
    slli t0, t0, 3      # cada glifo ocupa 8 bytes
    la t1, GLYPHS
    add a3, t1, t0
    mv a0, s8
    mv a1, s9
    mv a2, s10
    jal DRAW_GLYPH
    addi s8, s8, 12     # avança uma letra (9 px + espaço)
    addi s11, s11, 1
    j T_LOOP
T_END:
    lw ra, 0(sp)
    lw s8, 4(sp)
    lw s9, 8(sp)
    lw s10, 12(sp)
    lw s11, 16(sp)
    addi sp, sp, 20
    ret

# ---------- DRAW_GLYPH: a0=x, a1=y, a2=cor, a3=endereço do glifo (3x5, escala 3) ----------
DRAW_GLYPH:
    addi sp, sp, -28
    sw ra, 0(sp)
    sw s2, 4(sp)
    sw s3, 8(sp)
    sw s8, 12(sp)
    sw s9, 16(sp)
    sw s10, 20(sp)
    sw s11, 24(sp)
    mv s8, a0
    mv s9, a1
    mv s10, a2
    mv s11, a3
    li s2, 0            # linha
G_ROW:
    li s3, 0            # coluna
G_COL:
    add t1, s11, s2
    lb t0, 0(t1)        # bits da linha
    li t2, 2
    sub t2, t2, s3
    srl t0, t0, t2
    andi t0, t0, 1
    beqz t0, G_SKIP
    slli t1, s3, 1
    add t1, t1, s3      # col*3
    add a0, s8, t1
    slli t1, s2, 1
    add t1, t1, s2      # linha*3
    add a1, s9, t1
    mv a2, s10
    li a3, 3
    li a4, 3
    jal RECT
G_SKIP:
    addi s3, s3, 1
    li t0, 3
    blt s3, t0, G_COL
    addi s2, s2, 1
    li t0, 5
    blt s2, t0, G_ROW
    lw ra, 0(sp)
    lw s2, 4(sp)
    lw s3, 8(sp)
    lw s8, 12(sp)
    lw s9, 16(sp)
    lw s10, 20(sp)
    lw s11, 24(sp)
    addi sp, sp, 28
    ret

# ---------- KEY2: apenas verifica se há tecla pressionada ----------
# retorno: s1 = tecla (0 se nenhuma)
KEY2:
    li t1, 0xFF200000   # endereço de controle do KDMMIO
    li s1, 0            # assume que não há tecla
    lw t0, 0(t1)        # lê bit de controle do teclado
    andi t0, t0, 0x0001 # mascara o bit menos significativo
    beq t0, zero, FIM   # sem tecla: vai para FIM
    lw s1, 4(t1)        # lê o valor da tecla
    sw s1, 12(t1)       # echo da tecla no display do KDMMIO
FIM:
    ret

# ---------- DRAW: quadrado 8x8 (a0 = x, a1 = y, a2 = cor) ----------
DRAW:
    li a3, 8
    li a4, 8
    j RECT              # tail call, o ret do RECT volta para quem chamou DRAW

# ---------- RECT: a0=x, a1=y, a2=cor, a3=largura, a4=altura ----------
RECT:
    slli t1, a1, 8      # y*256
    slli t2, a1, 6      # y*64
    add t1, t1, t2      # y*320
    add t1, t1, a0      # + x
    li t2, 0xff000000
    add t1, t1, t2      # endereço do pixel (x,y)
    mv t3, a4           # linhas
R_ROW:
    mv t4, a3           # colunas
    mv t5, t1
R_COL:
    sb a2, 0(t5)
    addi t5, t5, 1
    addi t4, t4, -1
    bnez t4, R_COL
    addi t1, t1, 320    # próxima linha
    addi t3, t3, -1
    bnez t3, R_ROW
    ret
    
.include "render.asm"


# =====================================================
.data

RETDRAW:.word 1




# cada glifo: 5 linhas de 3 bits + 3 bytes de padding
# índices: 0=V 1=O 2=L 3=T 4=A 5=R 6=C 7=N 8=F 9=I 10=G
GLYPHS:
    .byte 5,5,5,5,2,0,0,0   # V
    .byte 7,5,5,5,7,0,0,0   # O
    .byte 4,4,4,4,7,0,0,0   # L
    .byte 7,2,2,2,2,0,0,0   # T
    .byte 2,5,7,5,5,0,0,0   # A
    .byte 6,5,6,5,5,0,0,0   # R
    .byte 3,4,4,4,3,0,0,0   # C
    .byte 5,7,7,5,5,0,0,0   # N
    .byte 7,4,6,4,4,0,0,0   # F
    .byte 7,2,2,2,7,0,0,0   # I
    .byte 3,4,5,5,3,0,0,0   # G

STR_VOLTAR: .byte 0,1,2,3,4,5,-1      # V O L T A R
STR_CONFIG: .byte 6,1,7,8,9,10,-1     # C O N F I G
