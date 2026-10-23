.data
.text
.globl intro

intro:
#o codigo continua tocando
li s2, 2           # inicializa ocontador para duas repeticoes
LOOP_2X:
      #trilha do menu
      li a0, 50    #50(D3)
      li a1, 1000  #duracao
      li a2, 9     #instrumento
      li a3, 100   #vol
      li a7, 33    #cod syscall
      ecall
      
      li a7,33     #cod syscall
      li a0, 53    #53(F3)
      li a1, 1000  #duracao
      #a2 e a3 mantem
      ecall
      
      addi s2, s2, -1    #diminui o contador
      bnez s2, LOOP_2X   #se t1 nao for zero, volta ao LOOP. Se for zero, vai para o LOOP2 
      
      li s2, 2     #reiniciar cont para 2 rep
LOOP1_2X: 
      li a0, 52    #52(E3)
      li a1, 1000  #duracao
      li a7, 33    #cod syscall
      ecall
      
      li a7, 33    #cod syscall
      li a0, 55    #55(G3)
      li a1, 1000  #duracao
      ecall
      
      addi s2, s2, -1    #diminui o contador
      bnez s2, LOOP1_2X  #se t1 nao for zero, volta ao LOOP. Se for zero, vai para o LOOP2 
      
      li s2, 2     #reiniciar cont para 2 rep
LOOP3_2X:
      #trilha basic
      li a0, 50    #50(D3)
      li a1, 1000  #duracao
      li a2, 9     #instrumento
      li a3, 100   #vol
      li a7, 33    #cod syscall
      ecall
      
      li a7,33     #cod syscall
      li a0, 53    #53(F3)
      li a1, 1000  #duracao
      #a2 e a3 mantem
      ecall
      
      addi s2, s2, -1    #diminui o contador
      bnez s2, LOOP3_2X   #se t1 nao for zero, volta ao LOOP. Se for zero, vai para o LOOP2 
      
      li a0, 52    #52(E3)
      li a1, 1000  #duracao
      li a7, 33    #cod syscall
      ecall
      
      li a7, 33    #cod syscall
      li a0, 55    #55(G3)
      li a1, 1000  #duracao
      ecall
      
FINAL_NOTAS:
       
      li a0, 57   #57(A3)
      li a1, 500  #duracao
      li a7, 33   #cod syscall
      ecall
      
      li a0, 55   #55(G3)
      li a1, 500  #duracao
      li a7, 33   #cod syscall
      ecall
      
      li a0, 53   #53(F3)
      li a1, 500  #duracao
      li a7, 33   #cod syscall
      ecall
      
      li a0, 52   #52(E3)
      li a1, 500  #duracao
      li a7, 33   #cod syscall
      ecall
      

VERIFICA_TECLADO:
      # Lê o receptor de controle do teclado (MMIO)
      li t1, 0xff200000     # Endereço de controle do teclado
      lw t2, 0(t1)        # Lê o status do teclado
      andi t2, t2, 1      # Verifica se alguma tecla foi pressionada
      beqz t2, REINICIA   # Se NENHUMA tecla foi pressionada, vai direto para REINICIA

      # Se uma tecla foi pressionada, verifica qual foi:
      lw t3, 4(t1)        # Lê o caractere digitado (fica no endereço 0xffff0004)
      li t4, 113          # Código ASCII da letra 'q'
      beq t3, t4, fim     # Se a tecla for 'q', pula para o fim e encerra
 
REINICIA:
      j intro              # Se não apertou 'q', repete a música inteira automaticamente

fim:
      #so chega aqui se a caractere for digitado no inicio
      li a7, 10   #syscall 10 encerra(exit)
      ecall
      
