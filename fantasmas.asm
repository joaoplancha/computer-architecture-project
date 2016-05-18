
fant_lin		EQU		0DH
fant_col		EQU		0FH

; estado dos fantasmas:
; 0 - nao inicializados
; 1 - a inicializar
; 3 - na caixa
; 4 - no jogo

fant_stt	:	STRING	0H,0H,0H,0H 
; estado 1 fantasma em cada posicao da string
; fantasma0, fantasma1, fantasma2, fantasma3

fant_pos	:	WORD 	0D0FH
				WORD 	0D0FH
				WORD 	0D0FH
				WORD 	0D0FH
; posicao de 1 fantasma em cada posicao da tabela
; a posicao inicial e a mesma para todos

fant_dorme		EQU		0H
fant_acorda		EQU		1H
fant_caixa		EQU		5H 	; 2, 3, 4, 5, esta na caixa
fant_jogo		EQU		6H	; esta em jogo

; Recebe apontador relativo para o fantasma a actuar
; guarda-0 em R10
; nao muda R10 ate ao final do ciclo
; alternativamente substituimos R10 por uma posicao de memoria

ciclo_fant:
	PUSH	R0
	PUSH	R1
	PUSH	R2
	PUSH	R3
	PUSH	R4
	PUSH	R5
	PUSH	R6
	PUSH	R7
	PUSH	R8
	PUSH	R9
	PUSH	R10

	MOV		R0,fant_stt		; R0 = Apontador para estado do fantasma
	MOV		R3,[R0]			; R3 = Estado do fantasma
	MOV 	R4,fant_pos		; R4 = Apontador para posicao do fantasma

	; IFs
	CMP		R3,fant_dorme	; Se estiver nao inicializado
	JZ		sai_fant		; sai sem fazer nada

	CMP		R3,fant_acorda 	; Se estiver marcado para inicializar
	JZ		acorda_fant		; vai acordar o fantasma
							; se nao for 0 ou 1, vamos ver se esta na caixa
	CMP		R3,fant_caixa	; Se estiver dentro da caixa
	JLE		saicx_fant		; 2-4 vai mover-se para cima, 5 sai da caixa

	CMP		R3,fant_jogo	; Se estiver fora da caixa, esta em jogo
	JZ		joga_fant		; vai mover-se na direccao do pacman

acorda_fant:
	MOV 	R5,fant_lin		; coloca a linha inicial do fantasma em R5
	MOV 	R6.fant_col		; coloca a coluna inicial do fantasma em R6
	MOV 	R8,fantasma 	; coloca o desenho do fantasma em R8
	CALL	desenha			; desenha o fantasma com R5, R6 e R8
	ADD		R3,1
	MOV 	[R0],R3			; actualiza o estado do fantasma
	JMP		sai_fant 		;
saicx_fant:
	MOVB 	R5,[R4]			; R5 = linha actual do fantasma
	MOVB	R6,[R4+1]		; R6 = coluna actual do fantasma
	CALL	move_fant		; Chama rotina para mover o fantasma
	MOVB	[R4],R5 		; nova linha do fantasma registada em memoria
	MOVB	[R4+1],R6		; nova coluna do fantasma registada em memoria
	ADD		R3,1
	MOV 	[R0],R3			; actualiza o estado do fantasma
	CMP		R3,fant_caixa	; verifica se ainda esta na caixa
	JGT		avisa			; se ja saiu da caixa
	JMP		sai_fant 		;
avisa:
;	MOV						; avisa que outro fantasma pode ser acordado
;	JMP

joga_fant:
	MOVB 	R5,[R4]			; R5 = linha actual do fantasma
	MOVB	R6,[R4+1]		; R6 = coluna actual do fantasma
	SUB 	R5,R1 			; diferenca entre linha do fantasma e do pacman
	SUB 	R6,R2			; diferenca entre coluna do fantasma e do pacman
	JMP		sai_fant 		;
sai_fant:
	POP		R10
	POP		R9
	POP		R8
	POP		R7
	POP		R6
	POP		R5
	POP		R4
	POP		R3
	POP		R2
	POP		R1
	POP		R0
	RET 
