# =====================================================
#  data/config.s - constantes do jogo (edite à vontade)
#  Cores no formato RRRGGGBB (1 byte).
# =====================================================
.eqv COR_JOGADOR   0xFF     # branco
.eqv COR_INIMIGO   0xE0     # vermelho
.eqv COR_TIRO_J    0x00     # preto  (tiro do jogador)
.eqv COR_TIRO_I    0xFC     # amarelo (tiro dos inimigos)
.eqv COR_BLOCO     0x88     # marrom (obstáculos)
.eqv COR_VIDA      0x1C     # verde (vidas no HUD)

.eqv TAM_JOG       8        # jogador 8x8
.eqv TAM_INIM      6        # inimigo 6x6
.eqv TAM_TIRO      3        # tiro 3x3

.eqv PASSO_JOG     4        # pixels por tecla do jogador
.eqv VEL_TIRO      4        # velocidade do tiro do jogador (px/quadro)
.eqv VEL_TIRO_I    3        # velocidade do tiro dos inimigos
.eqv VEL_INIM      2        # velocidade dos inimigos

.eqv MAX_TIROS     16       # tiros simultâneos na tela
.eqv MAX_INIM      6        # máximo de inimigos por mapa
.eqv VIDAS_INI     3
.eqv HUD_H         12       # altura da barra superior (HUD)
.eqv FRAME_MS      30       # pausa entre quadros (ms)
