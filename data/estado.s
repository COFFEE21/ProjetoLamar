# =====================================================
#  data/estado.s - variáveis do jogo (mudam durante a execução)
#  TIROS:  24 bytes cada = [ativo, x, y, dx, dy, dono(0=jogador,1=inimigo)]
#  INIMS:  32 bytes cada = [vivo, x, y, dx, dy, timer_mov, timer_tiro, -]
# =====================================================
.data
.align 2
SEED:        .word 0x12345679
VIDAS:       .word 3
INIM_VIVOS:  .word 0
FIM_FLAG:    .word 0        # 0 jogando, 1 perdeu, 2 venceu
MAPA_ATUAL:  .word 0
FUNDO:       .word 0        # cor de fundo do mapa (1 byte)
OBST_PTR:    .word 0
OBST_N:      .word 0
TIROS:       .space 384     # MAX_TIROS * 24
INIMS:       .space 192     # MAX_INIM * 32
