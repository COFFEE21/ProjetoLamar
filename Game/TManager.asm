.data

#espaço reservado para os includes dos arquivos

.include "../Res/tijolo.s"
.include "../Res/grama.s"


#fim dos includes


SPRITELIST: .word TIJOLO, GRAMA



#Registradores que eu NÃO POSSO USAR: #s0 #s1 #s2 #s7 #s8




.text
 
.globl TMANAGER
 
   	 	 
TMANAGER:
	la t1, SPRITELIST
	#addi t1, t1, 0 #endereço que escolhe qual sprite vai ser printado!
	
	jal tp , LOADLEVEL	# chama a função load Level (retorno vai ser somado a t1)
	
	lw t4, 0(t1) #Endereço dos sprite referenciado pela label na SPRITESLIST 
	jalr zero, 0(ra) #ret explícito
	
	
.include "LevelL.asm" #include no LevelLoader
	
