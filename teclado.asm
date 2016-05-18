; *********************************************************************
; *
; * IST-UTL
; *
; *********************************************************************

; *********************************************************************
; *
; * Modulo: 	teclado.asm
; * Descrição : lê a tecla que foi premida no teclado. 
; * enquanto o utilizador tem a tecla premida apresenta o valor da tecla
; *	quando o utilizador larga a tecla, soma 1 unidade ao valor mostrado
; * 
; * Ver.1:	18-03-2016 JPS
; * Ver.2:	07-04-2016 JPS
; *
; * adaptado de: lab asm3
; * Ver.1 :	01-03-2011 JCD
; * Ver.2 :	01-03-2012 RMR
; *
; * Nota : 	Observar a forma como se acede aos portos de E/S de 8 bits
; *		através da instrução MOVB
; *********************************************************************

; **********************************************************************
; * Constantes
; **********************************************************************
BUFFER	EQU	100H	; endereço de memória onde se guarda a tecla		
LINHA	EQU	1		; posição do bit correspondente à linha (1) a testar
PIN		EQU	0E000H	; endereço do porto de S do teclado
POUT2	EQU	0C000H	; endereço do porto de E do teclado
POUT3	EQU	06000H	; endereço do porto de E do display hexa extra
MASK	EQU	10H		; mascara para ver se ja saimos do teclado
; **********************************************************************
; * Código
; **********************************************************************
PLACE		0
inicio:					; Inicializações gerais
	;MOV 	R5,BUFFER	; R5: onde vamos guardar a tecla
	MOV		R2,PIN		; R2: endereco de saida do teclado
	MOV		R10,POUT2	; R10: endereco de entrada do teclado
	MOV		R6,MASK		; R6: guarda a mascara 10H
	MOV		R4,4		; Valor usado para calculo no ciclo conv_key

frst_line:				; Inicio do varrimento pela linha 1
	MOV		R1,LINHA	; Comeca/volta a linha 1 do teclado
						; R1: valor da linha do telcado em que estamos
	JMP		chk_pressed	; Salta para a verificacao se a tecla foi 
						; premida (neste caso para a linha 1)
nxt_line:				; Continuacao do varrimento pela linha seguinte
	SHL		R1,1		; Passa a linha seguinte
	CMP		R1,R6		; Verifica se ja chegamos a linha 5 (n existe)
	JNZ		chk_pressed	; Se ainda estamos numa das 4 linhas existentes 
						; verifica se alguma tecla foi premida
	JMP		frst_line	; Caso contrario, reinicia o varrimento pela
						; primeira linha do teclado novamente
chk_pressed:			; Verifica se alguma tecla da linha foi premida
	MOVB 	[R10],R1	; Escrever no porto de saída (entrada do tecl.)
						; indica ao teclado a linha a ver
	MOVB 	R3,[R2]		; Ler do porto de entrada (saida do tecl.)
						; regista se alguma tecla foi premida
	AND 	R3,R3		; Afectar as flags (MOVs não afectam as flags)
	JZ 		nxt_line	; Nenhuma tecla premida, passar a linha seguinte
	MOV		R7,R1		; Tecla premida - guarda o valor da linha 
						; (1,2,4 ou 8) no registo R7
	SHL		R7,8		; Empurra o valor da linha para o byte mais 
						; significativo do registo R7 
						; (0000.0000 0000.0010 -> 0000.0010 0000.0000) 
	ADD		R7,R3		; Adiciona a coluna a R7 fica Byte1,Byte2=L,C
						; (0000.0010 0000.0000 -> 0000.0010 0000.0100) 
	;MOV		[R5],R7		; Guarda no buffer de memoria, apontado por R5 
						; a linha e coluna registados em R7
	;ADD		R5,2		; R5 passa a apontar para o endereco de memoria 
						; seguinte, para guardar a proxima tecla premida
						; Os passos segunintes vao converter L,C para o 
						; valor efectivo da tecla premida (0 a F)
	MOV 	R8,1		; Inicializa R8 a 1 para contar linha
	MOV		R9,1		; Inicializa R9 a 1 para contar coluna
	MOV		R5,R1		; R5: guarda linha, para poder ser modificada
conv_lin:				
	SHR     R5,1		; Conta linha (vai variar entre 1 e 4)
	JZ		conv_col	; Ja chegou ao fim? se sim, vai contar coluna
	ADD		R8,1		; Se nao, adiciona um ao contador de linha
	JMP		conv_lin	; E volta ao conta linha
conv_col:	
	SHR		R3,1		; Conta coluna (vai variar entre 1 e 4)
	JZ		conv_key	; Se ja chegou ao fim, vai converter a tecla
	ADD		R9,1		; Se nao, adiciona um ao contador de coluna
	JMP		conv_col	; E volta ao conta coluna
conv_key:				; 
	SUB		R8,1		; Subtrai uma unidade ao numero da linha
	SUB		R9,1		; Subtrai uma unidade ao numero da coluna
	MUL		R8,R4		; Multiplica o valor da coluna-1 por 4 
	ADD		R9,R8		; Faz: (col-1) + (lin-1)*4 ... guarda em R9
	MOV		R8,POUT3	; R8: endreço de entrada do display hexa extra
	MOVB	[R8],R9		; Mostra valor da tecla no display
show_key:
	MOVB 	[R10],R1	; Escrever no porto de saída (entrada do tecl.)
						; indica ao teclado a linha a ver	
	MOVB 	R3,[R2]		; Ler do porto de entrada (saida do tecl.)
						; regista se alguma tecla esta a ser premida
	AND 	R3,R3		; Afecta as flags (MOVs não afectam as flags)
	JNZ 	show_key	; Tecla continua premida, nao vai sair do ciclo 
	ADD 	R9,1		; Quando a deixar de estar premida, soma 1 ao R9
	MOVB	[R8],R9		; Faz o display do R9 actual
	JMP 	frst_line	; Reinicia o varrimento do teclado

