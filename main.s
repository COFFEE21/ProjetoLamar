# =====================================================
#  main.s - TODO o código do jogo está neste arquivo.
#  Só os dados ficam separados na pasta "data" (ao lado deste arquivo).
#
#  Controles: w a s d move | i j k l atira | ESC pausa
# =====================================================
.include "data/config.s"       # constantes (.eqv): cores, tamanhos, velocidades

.text

# #####################################################
# ## jogo
# #####################################################
# =====================================================
#  script/jogo.s - fluxo do programa e loop do jogo
#  s5 = x, s4 = y do jogador (não usar em outras rotinas!)
#  O resto do estado fica na memória (data/estado.s)
# =====================================================
START:
    li a0, 1                # 1 opção (JOGAR)
    la a1, MAIN_TBL
    li a2, 0                # ESC não faz nada no menu inicial
    jal RUN_MENU            # só retorna ao escolher JOGAR

ESCOLHE_MAPA:
    li a0, 3                # MAPA 1, MAPA 2, VOLTAR
    la a1, MAPA_TBL
    li a2, 1                # ESC volta
    jal RUN_MENU
    bltz a0, START          # ESC
    li t0, 2
    beq a0, t0, START       # VOLTAR
    la t0, MAPA_ATUAL
    sw a0, 0(t0)            # 0 = mapa 1, 1 = mapa 2

START_GAME:
    jal INICIA_JOGO
    jal DESENHA_CENA

LOOP_JOGO:
    jal KEY2                # non-blocking: s1 = tecla ou 0
    beqz s1, LJ_SEM_TECLA
    li t4, 27               # ESC
    beq s1, t4, PAUSE
    jal TRATA_TECLA
LJ_SEM_TECLA:
    jal ATUALIZA_INIMS
    jal ATUALIZA_TIROS
    jal REDESENHA_ATORES
    la t0, FIM_FLAG
    lw t0, 0(t0)
    bnez t0, FIM_JOGO
    li a7, 32               # sleep
    li a0, FRAME_MS
    ecall
    j LOOP_JOGO

# ---------- menu de pausa (ESC) ----------
PAUSE:
    li a0, 3                # VOLTAR, CONFIG, MENU INICIAL
    la a1, PAUSE_TBL
    li a2, 1
    jal RUN_MENU
    li t4, 2
    beq a0, t4, START       # MENU INICIAL
    li t4, 1
    beq a0, t4, PAUSE       # CONFIG: ainda não implementado
    jal DESENHA_CENA        # VOLTAR ou ESC: redesenha tudo
    j LOOP_JOGO

# ---------- tela de fim (GAME OVER / VENCEU) ----------
FIM_JOGO:
    li a0, 0
    jal FILL_SCREEN
    la t0, FIM_FLAG
    lw t0, 0(t0)
    li t1, 2
    beq t0, t1, FJ_VENCEU
    li a0, 106
    li a1, 110
    li a2, 0xE0
    la a3, STR_GAMEOVER
    jal DRAW_TEXT
    j FJ_ESPERA
FJ_VENCEU:
    li a0, 124
    li a1, 110
    li a2, 0x1C
    la a3, STR_VENCEU
    jal DRAW_TEXT
FJ_ESPERA:
    li a7, 32
    li a0, 2500
    ecall
    j START

# #####################################################
# ## jogador
# #####################################################
# =====================================================
#  script/jogador.s - teclas, movimento e tiro do jogador
# =====================================================
# TRATA_TECLA: s1 = tecla. wasd move, ijkl atira (cima, esq., baixo, dir.)
TRATA_TECLA:
    addi sp, sp, -4
    sw ra, 0(sp)
    li t4, 'w'
    beq s1, t4, TT_W
    li t4, 's'
    beq s1, t4, TT_S
    li t4, 'a'
    beq s1, t4, TT_A
    li t4, 'd'
    beq s1, t4, TT_D
    li t4, 'i'
    beq s1, t4, TT_I
    li t4, 'k'
    beq s1, t4, TT_K
    li t4, 'j'
    beq s1, t4, TT_J
    li t4, 'l'
    beq s1, t4, TT_L
    j TT_FIM
TT_W:
    li a0, 0
    li a1, PASSO_JOG
    sub a1, zero, a1
    j TT_MOVE
TT_S:
    li a0, 0
    li a1, PASSO_JOG
    j TT_MOVE
TT_A:
    li a0, PASSO_JOG
    sub a0, zero, a0
    li a1, 0
    j TT_MOVE
TT_D:
    li a0, PASSO_JOG
    li a1, 0
TT_MOVE:
    jal MOVE_JOGADOR
    j TT_FIM
TT_I:
    li a0, 0
    li a1, -1
    j TT_ATIRA
TT_K:
    li a0, 0
    li a1, 1
    j TT_ATIRA
TT_J:
    li a0, -1
    li a1, 0
    j TT_ATIRA
TT_L:
    li a0, 1
    li a1, 0
TT_ATIRA:
    jal ATIRA_JOGADOR
TT_FIM:
    lw ra, 0(sp)
    addi sp, sp, 4
    ret

# MOVE_JOGADOR: a0 = dx, a1 = dy (pixels). Cancela se bater em borda/bloco.
MOVE_JOGADOR:
    addi sp, sp, -12
    sw ra, 0(sp)
    sw s8, 4(sp)
    sw s9, 8(sp)
    add s8, s5, a0          # novo x
    add s9, s4, a1          # novo y
    bltz s8, MJ_FIM
    li t2, 312              # 320 - 8
    bgt s8, t2, MJ_FIM
    li t2, HUD_H
    blt s9, t2, MJ_FIM
    li t2, 232              # 240 - 8
    bgt s9, t2, MJ_FIM
    mv a0, s8
    mv a1, s9
    li a2, TAM_JOG
    jal OBST_HIT
    bnez a0, MJ_FIM
    mv a0, s5               # apaga posição antiga
    mv a1, s4
    la t0, FUNDO
    lw a2, 0(t0)
    jal DRAW
    mv s5, s8
    mv s4, s9
    mv a0, s5               # desenha na nova
    mv a1, s4
    li a2, COR_JOGADOR
    jal DRAW
MJ_FIM:
    lw ra, 0(sp)
    lw s8, 4(sp)
    lw s9, 8(sp)
    addi sp, sp, 12
    ret

# ATIRA_JOGADOR: a0 = ux, a1 = uy (direção: -1, 0 ou 1)
ATIRA_JOGADOR:
    addi sp, sp, -4
    sw ra, 0(sp)
    li t0, VEL_TIRO
    mul a2, a0, t0          # dx do tiro
    mul a3, a1, t0          # dy do tiro
    li t1, 6
    mul t2, a0, t1          # deslocamento para fora do jogador
    mul t3, a1, t1
    addi a0, s5, 3          # centro do jogador - 1
    add a0, a0, t2
    addi a1, s4, 3
    add a1, a1, t3
    li a4, 0                # dono = jogador
    jal FIRE
    lw ra, 0(sp)
    addi sp, sp, 4
    ret

# JOGADOR_ACERTADO: perde uma vida
JOGADOR_ACERTADO:
    addi sp, sp, -4
    sw ra, 0(sp)
    la t0, VIDAS
    lw t1, 0(t0)
    addi t1, t1, -1
    sw t1, 0(t0)
    bgtz t1, JA_HUD
    la t0, FIM_FLAG
    lw t2, 0(t0)
    bnez t2, JA_HUD
    li t2, 1                # perdeu
    sw t2, 0(t0)
JA_HUD:
    jal DESENHA_HUD
    lw ra, 0(sp)
    addi sp, sp, 4
    ret

# #####################################################
# ## inimigos
# #####################################################
# =====================================================
#  script/inimigos.s - inimigos (pontos vermelhos)
#  Cada inimigo: [vivo, x, y, dx, dy, timer_mov, timer_tiro, -] (32 bytes)
#  Movimento: troca de direção a cada 15-44 quadros; 1/3 das vezes anda
#  na direção do jogador, nas outras é aleatório (inclusive parar).
#  Tiro: a cada 40-99 quadros, mirando no jogador (8 direções).
# =====================================================
# ATUALIZA_INIMS: move e faz atirar cada inimigo vivo
ATUALIZA_INIMS:
    addi sp, sp, -12
    sw ra, 0(sp)
    sw s8, 4(sp)
    sw s9, 8(sp)
    la s8, INIMS
    li s9, MAX_INIM
AI_LOOP:
    beqz s9, AI_FIM
    lw t0, 0(s8)
    beqz t0, AI_NEXT
    lw t0, 24(s8)           # recarga do tiro
    addi t0, t0, -1
    sw t0, 24(s8)
    bgtz t0, AI_MOVE
    jal INIM_ATIRA
AI_MOVE:
    jal INIM_MOVE
AI_NEXT:
    addi s8, s8, 32
    addi s9, s9, -1
    j AI_LOOP
AI_FIM:
    lw ra, 0(sp)
    lw s8, 4(sp)
    lw s9, 8(sp)
    addi sp, sp, 12
    ret

# INIM_ATIRA: s8 = inimigo. Atira na direção do jogador
INIM_ATIRA:
    addi sp, sp, -4
    sw ra, 0(sp)
    li a0, 60
    jal RAND_N
    addi a0, a0, 40
    sw a0, 24(s8)           # nova recarga
    lw t0, 4(s8)            # ex
    lw t1, 8(s8)            # ey
    sub t2, s5, t0          # jogador - inimigo (x)
    sub t3, s4, t1          # jogador - inimigo (y)
    li t4, 12
    sub t5, zero, t4
    li a2, 0                # sx
    ble t2, t4, IA_X1
    li a2, 1
    j IA_XOK
IA_X1:
    bge t2, t5, IA_XOK
    li a2, -1
IA_XOK:
    li a3, 0                # sy
    ble t3, t4, IA_Y1
    li a3, 1
    j IA_YOK
IA_Y1:
    bge t3, t5, IA_YOK
    li a3, -1
IA_YOK:
    bnez a2, IA_DIR_OK
    bnez a3, IA_DIR_OK
    li a3, 1                # em cima do jogador: atira para baixo
IA_DIR_OK:
    li t4, VEL_TIRO_I
    mul t5, a2, t4          # velocidade x
    mul t6, a3, t4          # velocidade y
    li t4, 5
    mul t2, a2, t4          # deslocamento para fora do inimigo
    mul t3, a3, t4
    add a0, t0, t2
    addi a0, a0, 2
    add a1, t1, t3
    addi a1, a1, 2
    mv a2, t5
    mv a3, t6
    li a4, 1                # dono = inimigo
    jal FIRE
    lw ra, 0(sp)
    addi sp, sp, 4
    ret

# INIM_MOVE: s8 = inimigo
INIM_MOVE:
    addi sp, sp, -12
    sw ra, 0(sp)
    sw s9, 4(sp)
    sw s10, 8(sp)
    lw t0, 20(s8)
    addi t0, t0, -1
    sw t0, 20(s8)
    bgtz t0, IM_ANDA
    jal INIM_ESCOLHE_DIR
IM_ANDA:
    lw s9, 4(s8)
    lw t0, 12(s8)
    add s9, s9, t0          # novo x
    lw s10, 8(s8)
    lw t0, 16(s8)
    add s10, s10, t0        # novo y
    bltz s9, IM_BATEU
    li t0, 314              # 320 - 6
    bgt s9, t0, IM_BATEU
    li t0, HUD_H
    blt s10, t0, IM_BATEU
    li t0, 234              # 240 - 6
    bgt s10, t0, IM_BATEU
    mv a0, s9
    mv a1, s10
    li a2, TAM_INIM
    jal OBST_HIT
    bnez a0, IM_BATEU
    mv a0, s9               # não entra em cima do jogador
    mv a1, s10
    li a2, TAM_INIM
    mv a3, s5
    mv a4, s4
    li a5, TAM_JOG
    jal OVERLAP
    bnez a0, IM_BATEU
    lw a0, 4(s8)            # apaga antigo
    lw a1, 8(s8)
    la t0, FUNDO
    lw a2, 0(t0)
    li a3, TAM_INIM
    li a4, TAM_INIM
    jal RECT
    sw s9, 4(s8)
    sw s10, 8(s8)
    mv a0, s9               # desenha novo
    mv a1, s10
    li a2, COR_INIMIGO
    li a3, TAM_INIM
    li a4, TAM_INIM
    jal RECT
    j IM_FIM
IM_BATEU:
    sw zero, 20(s8)         # escolhe outra direção no próximo quadro
IM_FIM:
    lw ra, 0(sp)
    lw s9, 4(sp)
    lw s10, 8(sp)
    addi sp, sp, 12
    ret

# INIM_ESCOLHE_DIR: s8 = inimigo. Define dx, dy e o timer de movimento
INIM_ESCOLHE_DIR:
    addi sp, sp, -4
    sw ra, 0(sp)
    li a0, 30
    jal RAND_N
    addi a0, a0, 15
    sw a0, 20(s8)           # timer = 15..44
    li a0, 3
    jal RAND_N
    bnez a0, ED_ALEATORIA   # 2/3: aleatório
    lw t0, 4(s8)            # 1/3: em direção ao jogador
    lw t1, 8(s8)
    sub t2, s5, t0
    sub t3, s4, t1
    mv t4, t2               # |dx|
    bgez t4, ED_A1
    sub t4, zero, t4
ED_A1:
    mv t5, t3               # |dy|
    bgez t5, ED_A2
    sub t5, zero, t5
ED_A2:
    blt t4, t5, ED_VERT
    li t6, VEL_INIM         # eixo horizontal
    bgez t2, ED_SET_X
    sub t6, zero, t6
ED_SET_X:
    sw t6, 12(s8)
    sw zero, 16(s8)
    j ED_FIM
ED_VERT:
    li t6, VEL_INIM         # eixo vertical
    bgez t3, ED_SET_Y
    sub t6, zero, t6
ED_SET_Y:
    sw zero, 12(s8)
    sw t6, 16(s8)
    j ED_FIM
ED_ALEATORIA:
    li a0, 5                # 0 cima, 1 baixo, 2 esq., 3 dir., 4 parado
    jal RAND_N
    li t6, VEL_INIM
    sub t5, zero, t6
    li t0, 0
    li t1, 0
    beqz a0, ED_UP
    li t2, 1
    beq a0, t2, ED_DOWN
    li t2, 2
    beq a0, t2, ED_LEFT
    li t2, 3
    beq a0, t2, ED_RIGHT
    j ED_SALVA
ED_UP:
    mv t1, t5
    j ED_SALVA
ED_DOWN:
    mv t1, t6
    j ED_SALVA
ED_LEFT:
    mv t0, t5
    j ED_SALVA
ED_RIGHT:
    mv t0, t6
ED_SALVA:
    sw t0, 12(s8)
    sw t1, 16(s8)
ED_FIM:
    lw ra, 0(sp)
    addi sp, sp, 4
    ret

# MATA_INIMIGO: a0 = ponteiro do inimigo
MATA_INIMIGO:
    addi sp, sp, -4
    sw ra, 0(sp)
    lw t0, 4(a0)
    lw a1, 8(a0)
    sw zero, 0(a0)          # vivo = 0
    mv a0, t0
    la t0, FUNDO
    lw a2, 0(t0)
    li a3, TAM_INIM
    li a4, TAM_INIM
    jal RECT                # apaga
    la t0, INIM_VIVOS
    lw t1, 0(t0)
    addi t1, t1, -1
    sw t1, 0(t0)
    bnez t1, MI_HUD
    la t0, FIM_FLAG
    lw t2, 0(t0)
    bnez t2, MI_HUD
    li t2, 2                # venceu
    sw t2, 0(t0)
MI_HUD:
    jal DESENHA_HUD
    lw ra, 0(sp)
    addi sp, sp, 4
    ret

# DESENHA_INIMS: desenha todos os inimigos vivos
DESENHA_INIMS:
    addi sp, sp, -12
    sw ra, 0(sp)
    sw s8, 4(sp)
    sw s9, 8(sp)
    la s8, INIMS
    li s9, MAX_INIM
DI_LOOP:
    beqz s9, DI_FIM
    lw t0, 0(s8)
    beqz t0, DI_NEXT
    lw a0, 4(s8)
    lw a1, 8(s8)
    li a2, COR_INIMIGO
    li a3, TAM_INIM
    li a4, TAM_INIM
    jal RECT
DI_NEXT:
    addi s8, s8, 32
    addi s9, s9, -1
    j DI_LOOP
DI_FIM:
    lw ra, 0(sp)
    lw s8, 4(sp)
    lw s9, 8(sp)
    addi sp, sp, 12
    ret

# REDESENHA_ATORES: repara inimigos e jogador no fim de cada quadro
REDESENHA_ATORES:
    addi sp, sp, -4
    sw ra, 0(sp)
    jal DESENHA_INIMS
    mv a0, s5
    mv a1, s4
    li a2, COR_JOGADOR
    jal DRAW
    lw ra, 0(sp)
    addi sp, sp, 4
    ret

# #####################################################
# ## tiros
# #####################################################
# =====================================================
#  script/tiros.s - tiros do jogador (pretos) e dos inimigos (amarelos)
#  Cada tiro: [ativo, x, y, dx, dy, dono] (24 bytes)
# =====================================================
# FIRE: cria um tiro. a0=x, a1=y, a2=dx, a3=dy, a4=dono (0 jogador, 1 inimigo)
# Não cria se estiver fora da tela, dentro de bloco ou sem espaço livre.
FIRE:
    addi sp, sp, -8
    sw ra, 0(sp)
    sw s8, 4(sp)
    bltz a0, F_FIM
    li t0, 317
    bgt a0, t0, F_FIM
    li t0, HUD_H
    blt a1, t0, F_FIM
    li t0, 237
    bgt a1, t0, F_FIM
    la s8, TIROS
    li t0, MAX_TIROS
F_BUSCA:
    beqz t0, F_FIM
    lw t1, 0(s8)
    beqz t1, F_ACHOU
    addi s8, s8, 24
    addi t0, t0, -1
    j F_BUSCA
F_ACHOU:
    sw a0, 4(s8)
    sw a1, 8(s8)
    sw a2, 12(s8)
    sw a3, 16(s8)
    sw a4, 20(s8)
    li a2, TAM_TIRO
    jal OBST_HIT            # a0, a1 ainda = x, y
    bnez a0, F_FIM
    li t1, 1
    sw t1, 0(s8)            # ativa
    lw a0, 4(s8)
    lw a1, 8(s8)
    lw t0, 20(s8)
    li a2, COR_TIRO_J
    beqz t0, F_DESENHA
    li a2, COR_TIRO_I
F_DESENHA:
    li a3, TAM_TIRO
    li a4, TAM_TIRO
    jal RECT
F_FIM:
    lw ra, 0(sp)
    lw s8, 4(sp)
    addi sp, sp, 8
    ret

# ATUALIZA_TIROS: move todos os tiros ativos e trata colisões
ATUALIZA_TIROS:
    addi sp, sp, -12
    sw ra, 0(sp)
    sw s8, 4(sp)
    sw s9, 8(sp)
    la s8, TIROS
    li s9, MAX_TIROS
AT_LOOP:
    beqz s9, AT_FIM
    lw t0, 0(s8)
    beqz t0, AT_NEXT
    lw a0, 4(s8)            # apaga na posição antiga
    lw a1, 8(s8)
    la t0, FUNDO
    lw a2, 0(t0)
    li a3, TAM_TIRO
    li a4, TAM_TIRO
    jal RECT
    lw t0, 4(s8)            # move
    lw t1, 12(s8)
    add t0, t0, t1
    sw t0, 4(s8)
    lw t0, 8(s8)
    lw t1, 16(s8)
    add t0, t0, t1
    sw t0, 8(s8)
    lw a0, 4(s8)
    lw a1, 8(s8)
    bltz a0, AT_MORRE       # saiu da tela
    li t0, 317
    bgt a0, t0, AT_MORRE
    li t0, HUD_H
    blt a1, t0, AT_MORRE
    li t0, 237
    bgt a1, t0, AT_MORRE
    li a2, TAM_TIRO
    jal OBST_HIT            # bateu em bloco
    bnez a0, AT_MORRE
    lw t0, 20(s8)
    bnez t0, AT_VS_JOG
    jal TIRO_VS_INIMIGOS    # tiro do jogador x inimigos
    bnez a0, AT_MORRE
    j AT_DESENHA
AT_VS_JOG:
    lw a0, 4(s8)            # tiro inimigo x jogador
    lw a1, 8(s8)
    li a2, TAM_TIRO
    mv a3, s5
    mv a4, s4
    li a5, TAM_JOG
    jal OVERLAP
    beqz a0, AT_DESENHA
    jal JOGADOR_ACERTADO
    j AT_MORRE
AT_DESENHA:
    lw a0, 4(s8)
    lw a1, 8(s8)
    lw t0, 20(s8)
    li a2, COR_TIRO_J
    beqz t0, AT_COR
    li a2, COR_TIRO_I
AT_COR:
    li a3, TAM_TIRO
    li a4, TAM_TIRO
    jal RECT
    j AT_NEXT
AT_MORRE:
    sw zero, 0(s8)
AT_NEXT:
    addi s8, s8, 24
    addi s9, s9, -1
    j AT_LOOP
AT_FIM:
    lw ra, 0(sp)
    lw s8, 4(sp)
    lw s9, 8(sp)
    addi sp, sp, 12
    ret

# TIRO_VS_INIMIGOS: s8 = tiro atual. Retorna a0 = 1 se acertou um inimigo
TIRO_VS_INIMIGOS:
    addi sp, sp, -12
    sw ra, 0(sp)
    sw s9, 4(sp)
    sw s10, 8(sp)
    la s9, INIMS
    li s10, MAX_INIM
TVI_LOOP:
    beqz s10, TVI_NAO
    lw t0, 0(s9)
    beqz t0, TVI_NEXT
    lw a0, 4(s8)
    lw a1, 8(s8)
    li a2, TAM_TIRO
    lw a3, 4(s9)
    lw a4, 8(s9)
    li a5, TAM_INIM
    jal OVERLAP
    beqz a0, TVI_NEXT
    mv a0, s9
    jal MATA_INIMIGO
    li a0, 1
    j TVI_FIM
TVI_NEXT:
    addi s9, s9, 32
    addi s10, s10, -1
    j TVI_LOOP
TVI_NAO:
    li a0, 0
TVI_FIM:
    lw ra, 0(sp)
    lw s9, 4(sp)
    lw s10, 8(sp)
    addi sp, sp, 12
    ret

# DESENHA_TIROS: desenha todos os tiros ativos
DESENHA_TIROS:
    addi sp, sp, -12
    sw ra, 0(sp)
    sw s8, 4(sp)
    sw s9, 8(sp)
    la s8, TIROS
    li s9, MAX_TIROS
DT_LOOP:
    beqz s9, DT_FIM
    lw t0, 0(s8)
    beqz t0, DT_NEXT
    lw a0, 4(s8)
    lw a1, 8(s8)
    lw t0, 20(s8)
    li a2, COR_TIRO_J
    beqz t0, DT_COR
    li a2, COR_TIRO_I
DT_COR:
    li a3, TAM_TIRO
    li a4, TAM_TIRO
    jal RECT
DT_NEXT:
    addi s8, s8, 24
    addi s9, s9, -1
    j DT_LOOP
DT_FIM:
    lw ra, 0(sp)
    lw s8, 4(sp)
    lw s9, 8(sp)
    addi sp, sp, 12
    ret

# #####################################################
# ## mapa
# #####################################################
# =====================================================
#  script/mapa.s - carrega mapa, desenha cena, obstáculos e HUD
# =====================================================
# INICIA_JOGO: carrega o mapa escolhido e zera o estado
INICIA_JOGO:
    addi sp, sp, -4
    sw ra, 0(sp)
    li a7, 30               # semente aleatória pelo relógio
    ecall
    ori a0, a0, 1
    la t0, SEED
    sw a0, 0(t0)

    la t0, INIMS            # zera inimigos
    li t1, MAX_INIM
    slli t1, t1, 3
IJ_Z1:
    sw zero, 0(t0)
    addi t0, t0, 4
    addi t1, t1, -1
    bnez t1, IJ_Z1
    la t0, TIROS            # zera tiros
    li t1, MAX_TIROS
    li t2, 6
    mul t1, t1, t2
IJ_Z2:
    sw zero, 0(t0)
    addi t0, t0, 4
    addi t1, t1, -1
    bnez t1, IJ_Z2

    la t0, VIDAS
    li t1, VIDAS_INI
    sw t1, 0(t0)
    la t0, FIM_FLAG
    sw zero, 0(t0)

    la t0, MAPA_ATUAL       # descritor do mapa
    lw t0, 0(t0)
    slli t0, t0, 2
    la t1, MAP_TBL
    add t1, t1, t0
    lw t1, 0(t1)
    lw t2, 0(t1)
    la t3, FUNDO
    sw t2, 0(t3)            # cor de fundo
    lw s5, 4(t1)            # posição inicial do jogador
    lw s4, 8(t1)
    lw t2, 12(t1)           # nº de obstáculos
    la t3, OBST_N
    sw t2, 0(t3)
    addi t4, t1, 20         # lista de obstáculos
    la t3, OBST_PTR
    sw t4, 0(t3)
    slli t2, t2, 4
    add t4, t4, t2          # lista de inimigos
    lw t5, 16(t1)           # nº de inimigos
    la t3, INIM_VIVOS
    sw t5, 0(t3)
    la t6, INIMS
    li t0, 0
IJ_INIM:
    bge t0, t5, IJ_FIM
    lw a0, 0(t4)
    lw a1, 4(t4)
    li a2, 1
    sw a2, 0(t6)            # vivo
    sw a0, 4(t6)            # x
    sw a1, 8(t6)            # y
    slli a3, t0, 4
    addi a3, a3, 30
    sw a3, 24(t6)           # primeira recarga escalonada
    addi t4, t4, 8
    addi t6, t6, 32
    addi t0, t0, 1
    j IJ_INIM
IJ_FIM:
    lw ra, 0(sp)
    addi sp, sp, 4
    ret

# DESENHA_CENA: fundo, blocos, inimigos, tiros, jogador e HUD
DESENHA_CENA:
    addi sp, sp, -4
    sw ra, 0(sp)
    la t0, FUNDO
    lw a0, 0(t0)
    slli t1, a0, 8          # repete o byte nos 4 pixels do word
    or a0, a0, t1
    slli t1, a0, 16
    or a0, a0, t1
    jal FILL_SCREEN
    jal DESENHA_OBST
    jal DESENHA_INIMS
    jal DESENHA_TIROS
    mv a0, s5
    mv a1, s4
    li a2, COR_JOGADOR
    jal DRAW
    jal DESENHA_HUD
    lw ra, 0(sp)
    addi sp, sp, 4
    ret

# DESENHA_OBST: blocos marrons do mapa
DESENHA_OBST:
    addi sp, sp, -12
    sw ra, 0(sp)
    sw s8, 4(sp)
    sw s9, 8(sp)
    la t0, OBST_N
    lw s9, 0(t0)
    la t0, OBST_PTR
    lw s8, 0(t0)
DO_LOOP:
    beqz s9, DO_FIM
    lw a0, 0(s8)
    lw a1, 4(s8)
    lw a3, 8(s8)
    lw a4, 12(s8)
    li a2, COR_BLOCO
    jal RECT
    addi s8, s8, 16
    addi s9, s9, -1
    j DO_LOOP
DO_FIM:
    lw ra, 0(sp)
    lw s8, 4(sp)
    lw s9, 8(sp)
    addi sp, sp, 12
    ret

# OBST_HIT: a0 = x, a1 = y, a2 = tamanho -> a0 = 1 se bate em algum bloco
OBST_HIT:
    la t0, OBST_N
    lw t1, 0(t0)
    la t0, OBST_PTR
    lw t0, 0(t0)
OH_LOOP:
    beqz t1, OH_NAO
    lw t2, 0(t0)            # rx
    lw t3, 4(t0)            # ry
    lw t4, 8(t0)
    lw t5, 12(t0)
    add t4, t4, t2          # rx + largura
    add t5, t5, t3          # ry + altura
    bge a0, t4, OH_NEXT
    bge a1, t5, OH_NEXT
    add t6, a0, a2
    ble t6, t2, OH_NEXT
    add t6, a1, a2
    ble t6, t3, OH_NEXT
    li a0, 1
    ret
OH_NEXT:
    addi t0, t0, 16
    addi t1, t1, -1
    j OH_LOOP
OH_NAO:
    li a0, 0
    ret

# DESENHA_HUD: barra preta no topo; vidas (verde) à esquerda,
# inimigos restantes (vermelho) à direita
DESENHA_HUD:
    addi sp, sp, -12
    sw ra, 0(sp)
    sw s8, 4(sp)
    sw s9, 8(sp)
    li a0, 0
    li a1, 0
    li a2, 0x00
    li a3, 320
    li a4, HUD_H
    jal RECT
    la t0, VIDAS
    lw s9, 0(t0)
    li s8, 4
DH_V:
    blez s9, DH_V_FIM
    mv a0, s8
    li a1, 3
    li a2, COR_VIDA
    li a3, 6
    li a4, 6
    jal RECT
    addi s8, s8, 10
    addi s9, s9, -1
    j DH_V
DH_V_FIM:
    la t0, INIM_VIVOS
    lw s9, 0(t0)
    li s8, 310
DH_I:
    blez s9, DH_FIM
    mv a0, s8
    li a1, 3
    li a2, COR_INIMIGO
    li a3, 6
    li a4, 6
    jal RECT
    addi s8, s8, -10
    addi s9, s9, -1
    j DH_I
DH_FIM:
    lw ra, 0(sp)
    lw s8, 4(sp)
    lw s9, 8(sp)
    addi sp, sp, 12
    ret

# #####################################################
# ## util
# #####################################################
# =====================================================
#  script/util.s - aleatório e colisão entre quadrados
# =====================================================
# RAND: a0 = número pseudo-aleatório de 32 bits (xorshift)
RAND:
    la t0, SEED
    lw a0, 0(t0)
    slli t1, a0, 13
    xor a0, a0, t1
    srli t1, a0, 17
    xor a0, a0, t1
    slli t1, a0, 5
    xor a0, a0, t1
    sw a0, 0(t0)
    ret

# RAND_N: a0 = n  ->  a0 = número em [0, n)
RAND_N:
    addi sp, sp, -8
    sw ra, 0(sp)
    sw a0, 4(sp)
    jal RAND
    lw t1, 4(sp)
    srli a0, a0, 8          # descarta bits baixos (mais fracos)
    remu a0, a0, t1
    lw ra, 0(sp)
    addi sp, sp, 8
    ret

# OVERLAP: dois quadrados se sobrepõem?
# a0=x1, a1=y1, a2=tam1, a3=x2, a4=y2, a5=tam2  ->  a0 = 1 ou 0
OVERLAP:
    add t0, a3, a5
    bge a0, t0, OV_NAO
    add t0, a4, a5
    bge a1, t0, OV_NAO
    add t0, a0, a2
    ble t0, a3, OV_NAO
    add t0, a1, a2
    ble t0, a4, OV_NAO
    li a0, 1
    ret
OV_NAO:
    li a0, 0
    ret

# #####################################################
# ## menu
# #####################################################
# =====================================================
#  script/menu.s - motor genérico de menu
# =====================================================
# RUN_MENU: a0 = nº de opções, a1 = tabela de textos,
#           a2 = 1 se ESC fecha o menu
# retorno:  a0 = opção escolhida (ou -1 se ESC)
# usa: s0 = selecionada, s6 = contagem, s7 = tabela, s2 = flag ESC
RUN_MENU:
    addi sp, sp, -4
    sw ra, 0(sp)
    mv s6, a0
    mv s7, a1
    mv s2, a2
    li s0, 0
    jal DRAW_MENU

RM_LOOP:
    jal KEY2
    beqz s1, RM_LOOP

    li t4, 27
    bne s1, t4, RM_NOESC
    beqz s2, RM_LOOP        # ESC desativado neste menu
    li a0, -1
    j RM_END
RM_NOESC:
    li t4, 'w'
    beq s1, t4, RM_UP
    li t4, 's'
    beq s1, t4, RM_DOWN
    li t4, 10               # Enter (LF)
    beq s1, t4, RM_OK
    li t4, 13               # Enter (CR)
    beq s1, t4, RM_OK
    j RM_LOOP

RM_UP:
    beqz s0, RM_LOOP
    addi s0, s0, -1
    jal DRAW_MENU
    j RM_LOOP

RM_DOWN:
    addi t0, s0, 1
    bge t0, s6, RM_LOOP
    mv s0, t0
    jal DRAW_MENU
    j RM_LOOP

RM_OK:
    mv a0, s0
RM_END:
    lw ra, 0(sp)
    addi sp, sp, 4
    ret

# DRAW_MENU: desenha as s6 opções da tabela s7
DRAW_MENU:
    addi sp, sp, -4
    sw ra, 0(sp)

    li a0, 0                # fundo preto
    jal FILL_SCREEN

    li s3, 0                # i
DM_LOOP:
    bge s3, s6, DM_END

    slli a1, s3, 5          # y = 70 + i*32
    addi a1, a1, 70

    li a2, 0x92             # cinza
    bne s3, s0, DM_COR
    li a2, 0xFC             # amarelo (selecionada)
DM_COR:
    li a0, 100
    slli t2, s3, 2
    add t2, s7, t2
    lw a3, 0(t2)            # endereço do texto da opção i
    jal DRAW_TEXT

    bne s3, s0, DM_NEXT
    li a0, 80               # marcador
    slli a1, s3, 5
    addi a1, a1, 74
    li a2, 0xFC
    jal DRAW
DM_NEXT:
    addi s3, s3, 1
    j DM_LOOP

DM_END:
    lw ra, 0(sp)
    addi sp, sp, 4
    ret

# #####################################################
# ## texto
# #####################################################
# =====================================================
#  script/texto.s - desenho de texto com a fonte 3x5
# =====================================================
# DRAW_TEXT: a0=x, a1=y, a2=cor, a3=string (índices, termina com -1)
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
    slli t0, t0, 3          # cada glifo ocupa 8 bytes
    la t1, GLYPHS
    add a3, t1, t0
    mv a0, s8
    mv a1, s9
    mv a2, s10
    jal DRAW_GLYPH
    addi s8, s8, 12         # avança uma letra
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

# DRAW_GLYPH: a0=x, a1=y, a2=cor, a3=glifo (3x5, escala 3)
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
    li s2, 0                # linha
G_ROW:
    li s3, 0                # coluna
G_COL:
    add t1, s11, s2
    lb t0, 0(t1)
    li t2, 2
    sub t2, t2, s3
    srl t0, t0, t2
    andi t0, t0, 1
    beqz t0, G_SKIP
    slli t1, s3, 1
    add t1, t1, s3          # col*3
    add a0, s8, t1
    slli t1, s2, 1
    add t1, t1, s2          # linha*3
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

# #####################################################
# ## grafico
# #####################################################
# =====================================================
#  script/grafico.s - primitivas gráficas (bitmap 320x240)
# =====================================================
# FILL_SCREEN: a0 = 4 pixels de cor (word)
FILL_SCREEN:
    li t0, 0xff000000
    li t1, 0xff012c00
FS_LOOP:
    sw a0, 0(t0)
    addi t0, t0, 4
    bltu t0, t1, FS_LOOP
    ret

# DRAW: quadrado 8x8 (a0 = x, a1 = y, a2 = cor)
DRAW:
    li a3, 8
    li a4, 8
    j RECT

# RECT: a0=x, a1=y, a2=cor, a3=largura, a4=altura
RECT:
    slli t1, a1, 8          # y*256
    slli t2, a1, 6          # y*64
    add t1, t1, t2          # y*320
    add t1, t1, a0          # + x
    li t2, 0xff000000
    add t1, t1, t2
    mv t3, a4
R_ROW:
    mv t4, a3
    mv t5, t1
R_COL:
    sb a2, 0(t5)
    addi t5, t5, 1
    addi t4, t4, -1
    bnez t4, R_COL
    addi t1, t1, 320
    addi t3, t3, -1
    bnez t3, R_ROW
    ret

# #####################################################
# ## teclado
# #####################################################
# =====================================================
#  script/teclado.s - leitura do teclado (KDMMIO)
# =====================================================
# KEY2: apenas verifica se há tecla pressionada
# retorno: s1 = tecla (0 se nenhuma)
KEY2:
    li t1, 0xFF200000
    li s1, 0
    lw t0, 0(t1)
    andi t0, t0, 0x0001
    beq t0, zero, FIM
    lw s1, 4(t1)
    sw s1, 12(t1)           # echo no display do KDMMIO
FIM:
    ret

# =====================================================
#  DADOS (pasta data)
# =====================================================
.include "data/fonte.s"
.include "data/textos.s"
.include "data/mapas.s"
.include "data/estado.s"
