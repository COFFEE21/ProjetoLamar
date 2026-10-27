
# =====================================================================
# render.asm
# Desenha o mapa de tiles (blocos) 16x16 na memória VGA (320x240, 8 bits/pixel).
# A tela é dividida em 20 colunas x 15 linhas de tiles (320/16 x 240/16).
# Para cada posição, o TMANAGER (em TManager.asm) devolve em t4 o endereço
# do tile a ser desenhado. Os 8 primeiros bytes do tile são cabeçalho e os
# pixels começam em t4+8.
#
# Convenção de chamada: quem chama usa "jal gp, DRAW0" (o endereço de
# retorno fica em gp, e não em ra) e o END volta para lá via RETDRAW.
# =====================================================================



.data
	
	
#.include "../Res/tijolo.s"
	


.text
	
	
# ---------- DRAW0: ponto de entrada da rotina de renderização ----------
DRAW0:
la a0,RETDRAW		# a0 = endereço da variável que guarda o retorno
sw gp,0(a0)		# salva o endereço de retorno (gp) em RETDRAW
	
        #li t1,0xFF000000	# endereco inicial da Memoria VGA - Frame 0
	#li t2,0xFF012C00	# endereco final 


# Mapa de registradores usados neste arquivo:
#s0, coluna!!!
#s1, linha!!!
#s2, 16
#s7, 240
#s8, 320
#s3, registrador temporário
#s4, registrador temporário 2       
        addi s0, zero, 0 #coluna   (começa na coluna 0)
	addi s1, zero, 0 #linha    (começa na linha 0)
	addi s2, zero, 16          # tamanho do tile em pixels
	addi s7, zero, 240         # altura da tela
	addi s8, zero, 320         # largura da tela

# ---------- SETUP: prepara o desenho de UM tile ----------
SETUP: #decide onde vai desenhar cada bloco(Tile)
	
	
	#la t4, TIJOLO		#endreço tijolo
	
	jal TMANAGER #Endereço da tile é retornado em t4 
	
	jal INLINHA #t1 armazena o resultado dessa função
	li t2,0xFF012C00	# endereco final do VGA (não é usado depois)
	jal FIMLINHA#t3 armazena o resultado dessa função
	addi t5, t4, 8		#começo dos bits de informação da tile
	li t6 , 16 #linhas para desenhar no próximo bloco
	j LOOP			# começa a copiar os pixels do tile



# ---------- INLINHA: calcula o endereço VGA do canto superior esquerdo do tile ----------
# endereço = 0xFF000000 + coluna*16 + linha*16*320
# saída: t1
INLINHA:#Função calcula o endreço inicial de cada bloco segundo o número de coluna e linha
	li t1 0xFF000000	# base da memória VGA
	
	
	#Vamos calcular qual a coluna atual
	add s3, zero, s0 #s3 = 0 + coluna
	mul s3, s3, s2   #s3 = s3 * s2(16)
	add t1, t1, s3   #t1 = t1+ s3 (adiciona as colunas ao endereço inicial)
	#fim do calculo da coluna
	
	#vamos calcular qual a linha inicial
	add s3, zero, s1 #s3 = 0 + s1(linha)
	mul s3, s3, s8   #s3 = s3 * s8(320)
	mul s3, s3, s2   # s3 = s3(linha*320) * s2(16)
	add t1, t1, s3   #t1 = t1 + s3
	#fim do calculo das linhas
	
	
	ret
	
	
				
# ---------- FIMLINHA: calcula onde termina a primeira linha de pixels do tile ----------
# t3 = t1 + 16 (fim da linha do tile)
FIMLINHA:#função calcula a linha final com base no valor de t1
	add t3, zero ,  t1 #t3 = t1(inicioda linha) 
	addi t3, t3, 16 #t3 = t3 + 16
	ret
				
						
# ---------- LOOP: copia o tile para a VGA, 4 pixels (1 word) por vez ----------
# t1 = ponteiro VGA | t3 = fim da linha atual do tile
# t5 = ponteiro dos dados do tile | t6 = linhas que ainda faltam
LOOP:	beqz t6, UP1		#Se todas as linhas do bloco forem carregdas jump para UP1
	
	beq t1,t3,UP		# Se o endereço VGA for igual ao endereço do final da linha
				#do bloco,va para a próxima da linha do bloco (UP)
	
	lw t0, 0(t5)		#Carregue as informações dos pixeis localizados em t5
	
	
	sw t0 ,0(t1)		# escreve a word na memória VGA
	
	addi t5, t5, 4		#soma quatro ao ponteiro para a data do tijolo para buscar
				#as informações dos 4 próximos pixeis
	
	addi t1,t1,4		# soma 4 ao endereço do VGA para poder carregar os 4 próximos
				#pixeis da tela
	j LOOP	


# ---------- UP: terminou uma linha de 16 pixels do tile, vai para a próxima linha ----------
UP:     #Rotina quando o máximo de colunas por linha forem renderizadas
	addi t1,t1, 320		#Passa para a próxima linha do bloco (OBS: somar 320 passa para a próxima linha
				#só que na mesma posição que ele estava, ou seja no final da linha, o que é indesejado nesse caso)
				
	addi t1, t1, -16	#Volta para a primeira coluna do bloco após ter pulado para a próxima linha
	addi t3, t3, 320	#atualiza o t3 = indice final da linha(indice em que o programa entende que chegou
				# ao final de uma linha) para ir até a próxima linha
				#OBS: note que, nesse caso, não precisamos subtrair 16, pois queremos que ele continue na mesma posição
				#quando saltar
				
	addi t6, t6, -1 	#Diminui uma das linhas do contador de linha(do bloco) a desenhar para que
				#o programa entenda que já desenhou uma linha naquele bloco.
				#OBS: A LINHA DESSE REGISTRADOR NÃO É A MESMA LINHA ARMAZENADA EM s1!!!
	
	j LOOP


# ---------- UP1: terminou o tile inteiro, avança para o próximo tile ----------
UP1:
	addi s0, s0, 1 #adiciona +1 para a coluna(da tela)
	
	mul s3, s0, s2 #s3 = s0(coluna) * s2(16)
	beq s3, s8, UP2 #se s3(coluna*16) == s7(320) adiciona mais 1 para linha
	
	mul s3, s1, s2 #s3 = s1(linha) * s2(16)
	beq s3 , s7, END # se S3(linha*16) == s8(240) encerre o programa
	
	
	j SETUP        #volta pro setup
	
# ---------- UP2: chegou no fim da linha de tiles, desce uma linha ----------
UP2:
	addi s1 , s1 , 1 #s1 = s1 + 1    (linha +1 )
	addi s0, zero, -1 # s0 = 0 + (-1) (coluna = -1)
	j UP1			# volta ao UP1, que soma +1 e deixa a coluna em 0 (e checa o fim da tela)

	
# ---------- END: fim da renderização, volta para quem chamou DRAW0 ----------
END: #encerra o programa

	
	la a0,RETDRAW		# a0 = endereço onde o retorno foi guardado
	lw s0,0(a0)		# s0 = endereço de retorno salvo no início (gp)
	jalr x0,0(s0)		# pula para esse endereço (retorna sem guardar link)
	
	#li a7, 10
	#ecall
	
	
.include "TManager.asm"		# rotina TMANAGER: escolhe qual tile desenhar (retorna em t4)
