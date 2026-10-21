
#t1 (não usar)

.data 
  .include "../Res/map1.s"

#MapIndex pode ser no máximo 300
MAPINDEX: .word 0 #referencia a quantidade de tile do mapa que foram caregados]

	


.text

LOADLEVEL:
	la t2, MAPINDEX #carrega o endereço do MAPINDEX
	lw t3, 0(t2)	#Carrega o número armazenado no endereço do MAPINDEX
	
	la  t4, MAP1 
	addi t4, t4, 8 #adiciona +8 para acessar os bytes de informação do mapa
	add t4, t4, t3 #endereço do byte de  informação do mapa (MAPINDEX + 8 + byte da posição MAP INDEX)
	lb t5, 0(t4)   #carrega o byte de informação do endereço t4  em t5
	add t1, t1, t5 #adiciona o resultado armazenado em t5 para t1
	
	addi t3, t3, 1 #adiciona +1 no meu MAPINDEX
	sw t3, 0(t2)   #Salva ele de volta na memória
	
	jalr zero, 0(tp) #ret para o TManager
