# =====================================================================
# riscv1.asm  -  Programa principal
# Um quadradinho 8x8 (personagem) que se move pelo mapa com W/A/S/D.
# ESC abre um menu (VOLTAR / CONFIG); no menu, W/S muda a opção e
# Enter confirma.
#
# Hardware (estilo RARS/FPGRARS):
#   VGA   : 0xFF000000 - 0xFF012C00, 320x240, 1 byte por pixel (RGB332)
#   KDMMIO: 0xFF200000 -> +0 controle (bit0 = tem tecla), +4 tecla, +12 eco no display
#
# Cores usadas (1 byte): 0x49 cinza escuro (fundo), 0xFF branco,
#                        0x92 cinza, 0xFC amarelo, 0x00 preto
#
# Registradores principais:
#   s0 = opção do menu (0 = VOLTAR, 1 = CONFIG)
#   s1 = tecla lida (0 = nenhuma)
#   s4 = y do personagem   s5 = x do personagem
#   s6 = dx (deslocamento em x)   s7 = dy (deslocamento em y)
# =====================================================================

.text
# ---------- pinta o mapa todo de escuro ----------
#li a0, 0x49494949		# 4 pixels de cor 0x49 (uma word)

jal  gp,DRAW0			# chama a renderização do mapa (render.asm); retorno guardado em gp

# ---------- posição inicial do personagem ----------
li s5, 156              # x
li s4, 116              # y

mv a0, s5			# a0 = x
mv a1, s4			# a1 = y
li a2, 0xff             # cor clara (branco)
jal DRAW			# desenha o personagem (quadrado 8x8)

# ---------- loop principal ----------
WHILE:
    jal KEY2            # key2 do lamar
    #local
    beqz s1, WHILE      # se tecla igual a zero jump para o while (aqui eh possivel colocar outras chamadas de funcao e outros processamentos)

    li t4, 27           # ESC codigos asc2 do esc eh 27
    beq s1, t4, MENU	# ESC -> abre o menu

    li s6, 0            # dx
    li s7, 0            # dy

    li t4, 'w'
    beq s1, t4, KW	# w -> cima
    li t4, 's'
    beq s1, t4, KS	# s -> baixo
    li t4, 'a'
    beq s1, t4, KA	# a -> esquerda
    li t4, 'd'
    beq s1, t4, KD	# d -> direita
    j WHILE             # tecla desconhecida: ignora

# define o deslocamento (4 pixels por passo) conforme a tecla
KW: li s7, -4		# cima: y diminui
    j MOVE
KS: li s7, 4		# baixo: y aumenta
    j MOVE
KA: li s6, -4		# esquerda: x diminui
    j MOVE
KD: li s6, 4		# direita: x aumenta
    j MOVE

# ---------- MOVE: apaga, atualiza posição, limita na tela e redesenha ----------
MOVE:
    # apaga na posição antiga (pinta de escuro)
    mv a0, s5
    mv a1, s4
    li a2, 0x49	# cor do fundo
    jal DRAW

    # atualiza posição
    add s5, s5, s6	# x += dx
    add s4, s4, s7	# y += dy

    # limites: x em [0,312], y em [0,232]   (320-8 e 240-8, pois o quadrado tem 8 px)
    bgez s5, X_OK1	# se x >= 0 está ok
    li s5, 0		# senão trava em 0
X_OK1:
    li t4, 312
    ble s5, t4, X_OK2	# se x <= 312 está ok
    li s5, 312		# senão trava em 312
X_OK2:
    bgez s4, Y_OK1	# se y >= 0 está ok
    li s4, 0		# senão trava em 0
Y_OK1:
    li t4, 232
    ble s4, t4, Y_OK2	# se y <= 232 está ok
    li s4, 232		# senão trava em 232
Y_OK2:

    # desenha na posição nova (cor clara)
    mv a0, s5
    mv a1, s4
    li a2, 0xff
    jal DRAW

    j WHILE		# volta ao loop principal

# =====================================================
#                       MENU
# s0 = opção selecionada (0 = VOLTAR, 1 = CONFIG)
# =====================================================
MENU:
    li s0, 0		# começa com VOLTAR selecionado
    jal DRAW_MENU	# desenha o menu

MENU_LOOP:
    jal KEY2		# lê tecla
    beqz s1, MENU_LOOP	# sem tecla: continua esperando

    li t4, 27           # ESC: volta ao jogo
    beq s1, t4, MENU_BACK
    li t4, 'w'		# w: sobe a seleção
    beq s1, t4, MENU_UP
    li t4, 's'		# s: desce a seleção
    beq s1, t4, MENU_DOWN
    li t4, 10           # Enter (LF)
    beq s1, t4, MENU_OK
    li t4, 13           # Enter (CR)
    beq s1, t4, MENU_OK
    j MENU_LOOP		# outra tecla: ignora

MENU_UP:
    li s0, 0		# seleciona VOLTAR
    jal DRAW_MENU	# redesenha com a nova seleção
    j MENU_LOOP

MENU_DOWN:
    li s0, 1		# seleciona CONFIG
    jal DRAW_MENU	# redesenha com a nova seleção
    j MENU_LOOP

MENU_OK:
    beqz s0, MENU_BACK  # VOLTAR
    # CONFIG: ainda não implementado
    j MENU_LOOP

# ---------- MENU_BACK: sai do menu e restaura o jogo ----------
MENU_BACK:
    li a0, 0x49494949   # redesenha o mapa
    jal FILL_SCREEN
    mv a0, s5           # e o personagem
    mv a1, s4
    li a2, 0xff
    jal DRAW
    j WHILE		# volta ao loop principal

# ---------- DRAW_MENU: desenha o menu conforme s0 ----------
DRAW_MENU:
    addi sp, sp, -4	# reserva espaço na pilha
    sw ra, 0(sp)	# salva ra (pois esta função chama outras)

    li a0, 0            # fundo preto
    jal FILL_SCREEN

    # opção 0: VOLTAR
    li a2, 0x92         # cinza (não selecionada)
    bnez s0, O0_COR	# se s0 != 0, mantém cinza
    li a2, 0xFC         # amarelo (selecionada)
O0_COR:
    li a0, 100		# x do texto
    li a1, 90		# y do texto
    la a3, STR_VOLTAR	# string "VOLTAR"
    jal DRAW_TEXT
    bnez s0, M0_SKIP	# só desenha o marcador se esta opção está selecionada
    li a0, 80           # marcador
    li a1, 94
    li a2, 0xFC
    jal DRAW
M0_SKIP:

    # opção 1: CONFIG
    li a2, 0x92		# cinza (não selecionada)
    beqz s0, O1_COR	# se s0 == 0, mantém cinza
    li a2, 0xFC		# amarelo (selecionada)
O1_COR:
    li a0, 100		# x do texto
    li a1, 130		# y do texto
    la a3, STR_CONFIG	# string "CONFIG"
    jal DRAW_TEXT
    beqz s0, M1_SKIP	# só desenha o marcador se esta opção está selecionada
    li a0, 80           # marcador
    li a1, 134
    li a2, 0xFC
    jal DRAW
M1_SKIP:

    lw ra, 0(sp)	# restaura ra
    addi sp, sp, 4	# libera a pilha
    ret

# ---------- FILL_SCREEN: a0 = 4 pixels de cor (word) ----------
# Preenche a VGA inteira escrevendo uma word (4 pixels) por vez.
FILL_SCREEN:
    li t0, 0xff000000	# início da VGA
    li t1, 0xff012c00	# fim da VGA
FS_LOOP:
    sw a0, 0(t0)	# escreve 4 pixels
    addi t0, t0, 4	# avança 4 bytes
    bltu t0, t1, FS_LOOP	# repete até chegar ao fim
    ret

# ---------- DRAW_TEXT: a0=x, a1=y, a2=cor, a3=string (índices, termina com -1) ----------
DRAW_TEXT:
    addi sp, sp, -20	# salva ra e s8..s11 na pilha
    sw ra, 0(sp)
    sw s8, 4(sp)
    sw s9, 8(sp)
    sw s10, 12(sp)
    sw s11, 16(sp)
    mv s8, a0		# s8  = x atual
    mv s9, a1		# s9  = y
    mv s10, a2		# s10 = cor
    mv s11, a3		# s11 = ponteiro da string
T_LOOP:
    lb t0, 0(s11)	# lê o índice da letra
    bltz t0, T_END	# -1 marca o fim da string
    slli t0, t0, 3      # cada glifo ocupa 8 bytes
    la t1, GLYPHS	# base da tabela de glifos
    add a3, t1, t0	# a3 = endereço do glifo da letra
    mv a0, s8
    mv a1, s9
    mv a2, s10
    jal DRAW_GLYPH	# desenha a letra
    addi s8, s8, 12     # avança uma letra (9 px + espaço)
    addi s11, s11, 1	# próxima letra da string
    j T_LOOP
T_END:
    lw ra, 0(sp)	# restaura registradores
    lw s8, 4(sp)
    lw s9, 8(sp)
    lw s10, 12(sp)
    lw s11, 16(sp)
    addi sp, sp, 20
    ret

# ---------- DRAW_GLYPH: a0=x, a1=y, a2=cor, a3=endereço do glifo (3x5, escala 3) ----------
# Cada pixel "aceso" do glifo vira um retângulo 3x3 (resultado: letra de 9x15 pixels).
DRAW_GLYPH:
    addi sp, sp, -28	# salva ra, s2, s3, s8..s11
    sw ra, 0(sp)
    sw s2, 4(sp)
    sw s3, 8(sp)
    sw s8, 12(sp)
    sw s9, 16(sp)
    sw s10, 20(sp)
    sw s11, 24(sp)
    mv s8, a0		# s8  = x
    mv s9, a1		# s9  = y
    mv s10, a2		# s10 = cor
    mv s11, a3		# s11 = endereço do glifo
    li s2, 0            # linha
G_ROW:
    li s3, 0            # coluna
G_COL:
    add t1, s11, s2	# endereço do byte da linha atual do glifo
    lb t0, 0(t1)        # bits da linha
    li t2, 2
    sub t2, t2, s3	# t2 = 2 - coluna (a coluna 0 é o bit mais alto)
    srl t0, t0, t2	# traz o bit da coluna para a posição 0
    andi t0, t0, 1	# isola o bit
    beqz t0, G_SKIP	# bit 0: pixel apagado, não desenha
    slli t1, s3, 1
    add t1, t1, s3      # col*3
    add a0, s8, t1	# x do retângulo = x + col*3
    slli t1, s2, 1
    add t1, t1, s2      # linha*3
    add a1, s9, t1	# y do retângulo = y + linha*3
    mv a2, s10		# cor
    li a3, 3		# largura 3
    li a4, 3		# altura 3
    jal RECT		# desenha o "pixel" ampliado
G_SKIP:
    addi s3, s3, 1	# próxima coluna
    li t0, 3
    blt s3, t0, G_COL	# 3 colunas por linha
    addi s2, s2, 1	# próxima linha
    li t0, 5
    blt s2, t0, G_ROW	# 5 linhas por glifo
    lw ra, 0(sp)	# restaura registradores
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
    li a3, 8		# largura 8
    li a4, 8		# altura 8
    j RECT              # tail call, o ret do RECT volta para quem chamou DRAW

# ---------- RECT: a0=x, a1=y, a2=cor, a3=largura, a4=altura ----------
# Preenche um retângulo de pixels (1 byte por pixel) na VGA.
RECT:
    slli t1, a1, 8      # y*256
    slli t2, a1, 6      # y*64
    
    #320y = (256 + 64)y, por isso usamos o add
    add t1, t1, t2      # y*320
    add t1, t1, a0      # + x
    li t2, 0xff000000
    add t1, t1, t2      # endereço do pixel (x,y)
    mv t3, a4           # linhas
R_ROW:
    mv t4, a3           # colunas
    mv t5, t1		# t5 = ponteiro do pixel atual na linha
R_COL:
    sb a2, 0(t5)	# escreve 1 pixel (byte de cor)
    addi t5, t5, 1	# próximo pixel
    addi t4, t4, -1	# uma coluna a menos
    bnez t4, R_COL
    addi t1, t1, 320    # próxima linha
    addi t3, t3, -1	# uma linha a menos
    bnez t3, R_ROW
    ret
    
.include "render.asm"		# traz DRAW0 (renderização do mapa de tiles)


# =====================================================
.data

RETDRAW:.word 1		# guarda o endereço de retorno do DRAW0 (usado em render.asm)




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
