# =====================================================
#  data/textos.s - strings (índices da fonte) e tabelas de menu
# =====================================================
.data
STR_JOGAR:    .byte 11,1,10,4,5,-1                    # JOGAR
STR_VOLTAR:   .byte 0,1,2,3,4,5,-1                    # VOLTAR
STR_CONFIG:   .byte 6,1,7,8,9,10,-1                   # CONFIG
STR_MENUINI:  .byte 12,13,7,14,15,9,7,9,6,9,4,2,-1    # MENU INICIAL
STR_MAPA1:    .byte 12,4,16,4,15,17,-1                # MAPA 1
STR_MAPA2:    .byte 12,4,16,4,15,18,-1                # MAPA 2
STR_GAMEOVER: .byte 10,4,12,13,15,1,0,13,5,-1         # GAME OVER
STR_VENCEU:   .byte 0,13,7,6,13,14,-1                 # VENCEU

.align 2
MAIN_TBL:  .word STR_JOGAR
PAUSE_TBL: .word STR_VOLTAR, STR_CONFIG, STR_MENUINI
MAPA_TBL:  .word STR_MAPA1, STR_MAPA2, STR_VOLTAR
