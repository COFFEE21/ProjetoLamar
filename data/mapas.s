# =====================================================
#  data/mapas.s - mapas
#  Cabeçalho: fundo, x_jogador, y_jogador, nº obstáculos, nº inimigos
#  Depois: obstáculos (x, y, largura, altura) e inimigos (x, y)
#  Área jogável: x de 0 a 319, y de 12 a 239 (acima é o HUD)
# =====================================================
.data
.align 2
MAP_TBL: .word MAPA1, MAPA2

MAPA1:
    .word 0x6D, 156, 216, 6, 4
    .word 50, 40, 48, 12
    .word 222, 40, 48, 12
    .word 136, 90, 48, 12
    .word 40, 120, 12, 48
    .word 268, 120, 12, 48
    .word 120, 160, 80, 12
    .word 30, 20
    .word 282, 20
    .word 150, 60
    .word 156, 125

MAPA2:
    .word 0x71, 156, 216, 6, 5
    .word 70, 30, 12, 60
    .word 238, 30, 12, 60
    .word 140, 60, 40, 40
    .word 30, 140, 100, 12
    .word 190, 140, 100, 12
    .word 150, 170, 20, 12
    .word 20, 20
    .word 290, 20
    .word 155, 25
    .word 10, 100
    .word 300, 100
