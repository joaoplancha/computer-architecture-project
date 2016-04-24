; *********************************************************************
; *
; * IST-UTL
; *
; *********************************************************************

; *********************************************************************
; *
; * Modulo: 	shape_draw.asm
; * Descrição : Acende um determinado conjunto de pixeis no ecra. 
; * 
; *	
; * 
; * Ver.1:	25-03-2016 JPS
; *
; * 
; *********************************************************************

; **********************************************************************
; * Constantes
; **********************************************************************
base	 	EQU	8000H	; endereço do inicio do pixelScreen
topo		EQU	8080H	; endereço do fim do pixelScreen

PLACE		1100H
pilha:		TABLE 100H		
SP_init:				; endereco de inicio do Stack Pointer

PLACE 		1000H		; definicao de mascaras e desenhos
;tabela de mascaras a usar pela rotina:
mascaras:	STRING	80H,40H,20H,10H,08H,04H,02H,01H	
desenho:	STRING	7H,4H,7H	; desenho do pacman
;desenho: 	STRING	5H,2H,5H	; desenho do fantasma
;desenho:	STRING 2H,7H,2H		; desenho do objecto
nl_des		EQU	3H				;n linhas que o desenho tem
; **********************************************************************
; * Código
; **********************************************************************
PLACE		0
;LIMPAR PIXELSCREEN
	MOV		R0,base		; Inicio do pixelscreen (canto superior esq)
	MOV		R1,topo		; Fim do pixelscreen (canto inferior dir)
	MOV		R3,0		; R3 = 0
limpa:		
	MOV		[R0],R3		; Coloca o endereço a zero = limpa o pixel
	ADD		R0,2		; Passa ao pixel seguinte
	CMP		R0,R1		; Verifica se já chegou ao fim do pixelscreen
	JNE		limpa		; Se nao, passa ao pixel seguinte e limpa


;INICIALIZACOES
	MOV		SP,SP_init	; Stack pointer aponta para a base da pilha
	MOV		R0,base		; R0: endereco de base do pixelscreen
	MOV		R4,4		; Inicializacao de valores usados em acende
	MOV		R5,8		; Inicializacao de valores usados em acende


;LOCALIZACAO DO PACMAN (em hexadecimal) a comecar em 0,0:
	MOV 	R1,0H		; Linha
	MOV 	R2,15H		; Coluna
	MOV 	R3,R2		; Coluna auxiliar - R2 vai ser destruido

;DECISAO DO PIXEL A ACENDER
	MOV 	R6,mascaras	; R6: ponteiro para o primeiro byte de mascaras
	MOVB 	R7,[R6]		; R7: primeiro valor de mascara
	MOV 	R8,desenho 	; R8: o ponteiro para o desenho
	MOVB 	R9,[R8]		; R9: primeira linha do desenho
	MOV 	R10,0		; R10: contador de linhas a desenhar
	JMP		checkbit	; Inicia o varrimento no checkbit
	
nxt_lin:		
	MOV 	R2,R3		; R2: Repoe o valor original de coluna
	ADD		R8,1 		; R8: Passa a linha seguinte do desenho
	MOVB	R9,[R8] 	; R9: Proxima linha do desenho
	MOVB 	R7,[R6]		; R7: Reinicia o valor da mascara
	ADD		R1,1		; R1: Adiciona um ao valor da linha
	ADD		R10,1		; R10: Adiciona um ao contador de linha
	CMP		R10,nl_des	; Ja passou da ultima linha do desenho?
	JZ		fim			; Se ja passou da ultima linha, vai para fim
						; Se nao, continua para o ckeckbit

checkbit:	
	AND 	R9,R7		; Verifica se ha bits comuns (a 1) entre a 
						; mascara escolhida e a linha do desenho
	JZ		nxt_col 	; Se nao houver, salta para nxt_col
	CALL 	acende 		; Se houver um bit comum (a 1) chama rotina que 
						; vai acender o pixel respectivo no ecra

nxt_col:		
	MOVB 	R9,[R8]		; Repoe o valor da primeira linha do pacman que 
						; tinha sido destruido pelo AND
	SHR		R7,1		; Passa para a mascara seguinte (de mascaras)
	JZ 		nxt_lin 	; Quando o SHR anterior passa de 0001 a 0000, 
						; nao tem mais colunas e salta para a prox. lin.
	ADD		R2,1 		; Caso contrario, adciona um ao valor da coluna
	JMP		checkbit 	; Volta para o checkbit, com a mascara para a 
						; coluna seguinte ja preparada (devido ao SHR)

fim:		
	JMP 	fim
	

; ROTINA ACENDE PIXEL -- Chamada com R1 = linha e R2 = coluna. 
; R1 e R2 variam entre 0 e 31.
acende:					
	;pushs
	PUSH	R1
	PUSH	R2
	PUSH	R3
	PUSH	R6
	PUSH	R7
	PUSH	R8
	MOV 	R3,R2		; Guarda a coluna em R3 (R2 vai ser destruido)
							
	;formula para endereco
	DIV		R2,R5
	MUL		R1,R4
	ADD		R1,R0
	ADD		R1,R2		; Endereço guardado em R1

	;formula para valor
	MOD		R3,R5		; Valor guardado em R3. 
						; R3: offset a somar a base de mascaras
								
	;busca mascara de acordo com valor calculado acima	
	MOV		R6,mascaras	; R6: inicio da tabela de mascaras
	ADD		R6,R3		; R6: endereco da mascara a usar
	MOVB	R7,[R6]		; R7: mascara a usar. Tem info do bit que 
						; queremos acender dentro de um certo byte
	
	;acende pixel
	MOVB	R8,[R1]		; Vai buscar os bits que ja estao acesos
	OR		R7,R8		; Junta o anterior ao bit que queremos acender
	MOVB	[R1],R7		;acende o bit em questao, deixando inalterado os
						; bits ja acesos dentro do byte
			
	;pops
	POP		R8
	POP		R7
	POP		R6
	POP		R3
	POP		R2
	POP		R1

	RET


		
		
