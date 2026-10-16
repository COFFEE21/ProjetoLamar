.data
	
	
.include "tijolo.s"

		
				


.text

        #li t1,0xFF000000	# endereco inicial da Memoria VGA - Frame 0
	#li t2,0xFF012C00	# endereco final 


#s0, coluna!!!
#s1, linha!!!
#s2, 16
#s7, 240
#s8, 320
#s3, registrador temporário
#s4, registrador temporário 2       
        addi s0, zero, 0 #coluna
	addi s1, zero, 0 #linha
	addi s2, zero, 16
	addi s7, zero, 240
	addi s8, zero, 320

SETUP: #decide onde vai desenhar cada bloco(Tile)

	jal INLINHA #t1 armazena o resultado dessa função
	li t2,0xFF012C00	# endereco final do VGA
	jal FIMLINHA#t3 armazena o resultado dessa função
	la t4, TIJOLO		#endreço tijolo
	addi t5, t4, 8		#começo dos bits de informação do tijolo
	li t6 , 16 #linhas para desenhar no próximo bloco
	j LOOP

INLINHA:#Função calcula o endreço inicial de cada bloco segundo o número de coluna e linha
	li t1 0xFF000000
	
	
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
	
	
				
FIMLINHA:#função calcula a linha final com base no valor de t1
	add t3, zero ,  t1 #t3 = t1(inicioda linha) 
	addi t3, t3, 16 #t3 = t3 + 16
	ret
				
						
LOOP:	beqz t6, UP1		#Se todas as linhas do bloco forem carregdas jump para UP1
	
	beq t1,t3,UP		# Se o endereço VGA for igual ao endereço do final da linha
				#do bloco,va para a próxima da linha do bloco (UP)
	
	lw t0, 0(t5)		#Carregue as informações dos pixeis localizados em t5
	
	
	sw t0 ,0(t1)		# escreve a word na mem�ria VGA
	
	addi t5, t5, 4		#soma quatro ao ponteiro para a data do tijolo para buscar
				#as informações dos 4 próximos pixeis
	
	addi t1,t1,4		# soma 4 ao endereço do VGA para poder carregar os 4 próximos
				#pixeis da tela
	j LOOP	


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


UP1:
	addi s0, s0, 1 #adiciona +1 para a coluna(da tela)
	
	mul s3, s0, s2 #s3 = s0(coluna) * s2(16)
	beq s3, s8, UP2 #se s3(coluna*16) == s7(320) adiciona mais 1 para linha
	
	mul s3, s1, s2 #s3 = s1(linha) * s2(16)
	beq s3 , s7, END # se S3(linha*16) == s8(240) encerre o programa
	
	
	j SETUP        #volta pro setup
	
UP2:
	addi s1 , s1 , 1 #s1 = s1 + 1    (linha +1 )
	addi s0, zero, -1 # s0 = 0 + (-1) (coluna = -1)
	j UP1

	
END: #encerra o programa
	li a7, 10
	ecall
