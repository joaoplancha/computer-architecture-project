; **********************************************************************
; *
; * IST-UTL
; *
; **********************************************************************
; **********************************************************************
; *
; * Projecto de Arquitetura de Computadores (2015/2016)
; * 
; * Pac-Man Simplificado
; *		
; *	51355 - João Plancha da Silva
; *
; **********************************************************************
; 
; Inicializacoes
;
; TECLADO:
BUFFER	EQU	100H	; endereço de memória onde se guarda a tecla		
LINHA	EQU	1		; posição do bit correspondente à linha (1) a testar
PIN		EQU	0E000H	; endereço do porto de S do teclado
POUT1	EQU	0A000H	; endereço do porto de E do display 
POUT2	EQU	0C000H	; endereço do porto de E do teclado
POUT3	EQU	06000H	; endereço do porto de E do display extra
MASK	EQU	10H		; mascara para ver se ja saimos do teclado
ES0_tec EQU	0FFH	; estado zero do teclado. pode receber novo comando


; **********************************************************************
; Desenhos
base	 	EQU	8000H	; endereço do inicio do pixelScreen
topo		EQU	8080H	; endereço do fim do pixelScreen
mask_linha	EQU	0FFFFH	
mask_colE	EQU	8000H
mask_colD	EQU	0001H
caixa_lin	EQU	0CH
caixa_col	EQU	0DH


; **********************************************************************
; * Stack 
; **********************************************************************
PLACE		2000H
pilha:		TABLE 400H		; espaço reservado para a pilha 
fim_pilha:				

; **********************************************************************
; * Dados
; **********************************************************************
PLACE		2600H
; tabela de mascaras a usar pela rotina shape_draw:
; desenhos podem ser modificados
; tamanho maximo: 7x7
mascaras:	STRING	80H,40H,20H,10H,08H,04H,02H,01H	
pac		:	STRING	7H,4H,7H	; desenho do pacman				
fant	: 	STRING	5H,2H,5H	; desenho do fantasma
obj		:	STRING 	2H,7H,2H	; desenho do objecto
caixa	:	STRING	63H,41H,41H,41H,41H,41H,7FH	; desenho da caixa
nlin	:	WORD	3H
ncol	:	WORD	3H

; correspondencia de teclas com movimento do pacman
tec_def	:	WORD	0FFFFH		; 0 - cima - esquerda	(-1,-1)
			WORD	0FFFFH
			WORD	0FFFFH		; 1 - cima				(-1, 0)
			WORD	0000H
			WORD	0FFFFH		; 2 - cima - direita	(-1, 1)
			WORD	0001H
			WORD	00FFH		; 3 - ND
			WORD	00FFH
			WORD	0000H		; 4 - esquerda			( 0,-1)
			WORD	0FFFFH
			WORD	00FFH		; 5 - ND
			WORD	00FFH
			WORD	0000H		; 6 - direita			( 0, 1)
			WORD	0001H
			WORD	00FFH		; 7 - ND
			WORD	00FFH
			WORD	0001H		; 8 - baixo - esquerda	( 1,-1)
			WORD	0FFFFH
			WORD	0001H		; 9 - baixo				( 1, 0)
			WORD	0000H
			WORD	0001H		; A - baixo - direita	( 1, 1)
			WORD	0001H
			WORD	00FFH		; B - ND
			WORD	00FFH
			WORD	00FFH		; C - ND
			WORD	00FFH
			WORD	00FFH		; D - ND
			WORD	00FFH
			WORD	00FFH		; E - ND
			WORD	00FFH

; teclas de controlo
rstrt		EQU		0FH			; reiniciar jogo
trmnt		EQU		0EH			; terminar jogo

nlin_def	EQU	3H
ncol_def	EQU	3H
nlin_cx		EQU	7H				; numero de linhas da caixa
ncol_cx		EQU	7H				; numero de colunas da caixa
pac_ini_L	EQU 1AH				; linha inicial do pacman
pac_ini_C	EQU 0DH				; coluna inicial do pacman

; linhas e colunas dos objectos
obj_L1		EQU	1H			
obj_L2		EQU	1CH
obj_C1		EQU	2H
obj_C2		EQU	1BH

; **********************************************************************
; Fantasmas
fant_lin		EQU		0DH
fant_col		EQU		0FH

; estado dos fantasmas:
; 0 - nao inicializados
; 1 - a inicializar
; 2-5 - na caixa
; 6 - no jogo

fant_stt	:	STRING	1H,0H,0H,0H 
; estado 1 fantasma em cada posicao da string
; fantasma0, fantasma1, fantasma2, fantasma3

fant_act	: 	STRING	0H; fantasma actual

fant_pos	:	WORD 	0D0FH
				WORD 	0D0FH
				WORD 	0D0FH
				WORD 	0D0FH
; posicao de 1 fantasma em cada posicao da tabela
; a posicao inicial e a mesma para todos

fant_desbl	:	WORD	0000H ; desbloqueio do fantasma
				WORD	0000H ; 2 WORDS pq ha desloc neg: FFFFH
desbl_cont	:	WORD	0000H ; contadores de desbloqueio
				WORD	0000H
				WORD	0000H
				WORD	0000H

pac_pos		:	WORD	1A0DH ;posicao do pacman

call_fant	:	WORD	0H	; variavel de chamada da interrupcao
							; 1 executa, 0 nao executa
conta_tempo	:	WORD	0H	; variavel de chamada da interrupcao
							; 1 conta tempo, 0 nao conta
contador	:	STRING	0H	; guarda a contagem de tempo

fant_dorme		EQU		0H
fant_acorda		EQU		1H
fant_caixa		EQU		5H 	; 2, 3, 4, 5, esta na caixa
fant_jogo		EQU		6H	; esta em jogo
fant_bloq_1		EQU		7H	; esta bloqueado em cima-baixo
fant_bloq_2		EQU		8H	; esta bloqueado a esquerda-direita

panic			EQU		2H	; 

; variaveis de estado
ON			EQU	1H
OFF			EQU	0H
keyb_stt:	WORD	1H ;(1 - ON, 0 - OFF)
keyb_lin:	WORD	1H
keyb_col:	WORD	1H
des_limp:	WORD	1H ;(1 - desenha, 0 - limpa)
move_ok:	WORD	0H 	;(0 - ok, 1 - bloqueado, 2 - bloq - panic)
chk_who:	WORD	0H ;(0 - pacman, 1 - fantasma)

; **********************************************************************
; Tabela de vectores de interrupção
tab:		WORD	sig0
			WORD	sig1


PLACE		0H	
	MOV		SP,fim_pilha; incializa SP
	MOV		BTE, tab	; incializa BTE
	MOV		R9,ES0_tec	; Coloca teclado no estado 0

init:
	; limpa ecra
	CALL	limpa
	CALL	desenha_ecra; desenha as barreiras
	

	; desenha o pacman na posicao inicial: 
	MOV		R1,pac_ini_L;
	MOV		R2,pac_ini_C;
	MOV		R8,pac		;
	CALL	desenha		;
	
	; desenha os objectos na posicao inicial:
	PUSH	R1
	PUSH	R2
	PUSH	R3
	PUSH	R4
	
	MOV		R1,obj_L1	;
	MOV		R2,obj_C1	;
	MOV		R8,obj		;
	CALL	desenha		;
	MOV		R1,obj_L1	;
	MOV		R2,obj_C2	;
	MOV		R8,obj		;
	CALL	desenha		;
	MOV		R1,obj_L2	;
	MOV		R2,obj_C1	;
	MOV		R8,obj		;
	CALL	desenha		;
	MOV		R1,obj_L2	;
	MOV		R2,obj_C2	;
	MOV		R8,obj		;
	CALL	desenha		;
	
	; coloca os fantasmas todos no estado inicial e posicao inicial:
	MOV		R1,fant_stt
	MOV		R2,0100H		; estado inicial dos fantasmas
	MOV		[R1],R2		; guarda estado inicial dos fantasmas em memoria
	MOV		R1,fant_pos	;
	MOV		R2,0D0FH	; posicao inicial do fantasma 1
	MOV		[R1],R2		; guarda a posicao inicial do fantasma 1 em mem
	
	; contador a zero
	MOV		R3,POUT1	; endereco do Periferico de saida 1
	MOV		R4,0		; comeca a contagem de segundos a zero
	MOV		[R3],R4		; coloca o valor no display
	MOV		R3,contador	; R3 = apontador para contador
	MOV		[R3],R4		; guarda o valor actual de contagem em memoria
	
	POP	R4
	POP	R3
	POP	R2
	POP R1
	EI0
	EI1
	EI
	
	
ciclo:
	CALL	conta		; contagem de tempo
	CALL	teclado		; Varrimento e leitura das teclas
	CALL	pacman		; Controlar movimentos do pacman
	CALL	fantasmas	; Controlar accoes dos fantasmas
	CALL	controlo	; Tratar das teclas de comecar e terminar
	CALL	gerador		; Gerar um numero aleatorio
	JMP		ciclo

; **********************************************************************
; PROCESSOS
; **********************************************************************
; **********************************************************************
; TECLADO
; R9: output - valor da tecla pressionada (0-F)
; **********************************************************************
teclado:
	PUSH	R0
	PUSH	R1
	PUSH	R2
	PUSH	R3
	PUSH	R4
	PUSH	R5
	PUSH	R6
	PUSH	R7
	PUSH	R8
	PUSH	R10
inicio:					; Inicializações gerais
	MOV		R2,PIN		; R2: endereco de saida do teclado
	MOV		R10,POUT2	; R10: endereco de entrada do teclado
	MOV		R6,MASK		; R6: guarda a mascara 10H
	MOV		R4,4		; Valor usado para calculo no ciclo conv_key
	
	MOV		R3,keyb_stt	; Busca o apontador para o estado do teclado
	MOV		R5,[R3]		; R5 = Estado do teclado (1-ON, 0-OFF)
	CMP		R5,OFF		; Se estiver OFF
	JZ		update_keyb	; Verifica se a tecla ja foi largada
	CMP		R5,ON		; Se estiver ON
	JZ		frst_line 	; Faz o varrimento normal do teclado
update_keyb:
	MOV		R9,ES0_tec	; R9: estado 0 - 00FFH
	MOV		R3,keyb_lin
	MOV		R1,[R3]		; Vai buscar a linha de onde leu e guardou
	MOVB 	[R10],R1	; Escrever no porto de saída (entrada do tecl.)
						; indica ao teclado a linha a ver	
	MOV		R3,keyb_col
	MOV		R5,[R3]		; Vai buscar a coluna de onde leu e guardou
	MOVB 	R3,[R2]		; Ler do porto de entrada (saida do tecl.)
						; regista se alguma tecla esta a ser premida
	PUSH	R1
	MOV		R1,000FH
	AND		R3,R1
	POP		R1
	CMP 	R5,R3		; Compara o que leu com o que esta a ler agora
	JZ 		sai_tec		; Tecla continua premida, sai sem fazer update 
	MOV		R3,keyb_stt	; Quando a deixar de estar premida,
	MOV		R5,ON		; Faz o update do estado do teclado para ON
	MOV		[R3],R5
	JMP 	sai_tec		; Sai da rotina do teclado
; inicia o varrimento
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
	JMP		sai_tec		; Caso contrario, sai do procedimento
chk_pressed:			; Verifica se alguma tecla da linha foi premida
	MOVB 	[R10],R1	; Escrever no porto de saída (entrada do tecl.)
						; indica ao teclado a linha a ver
	MOVB 	R3,[R2]		; Ler do porto de entrada (saida do tecl.)
						; regista se alguma tecla foi premida
	PUSH	R1
	MOV		R1,000FH
	AND		R3,R1
	POP		R1
	AND 	R3,R3		; Afectar as flags (MOVs não afectam as flags)
	JZ 		nxt_line	; Nenhuma tecla premida, passar a linha seguinte
	
	MOV		R7,keyb_lin
	MOV 	[R7],R1		; guarda linha na memoria
	MOV		R7,keyb_col
	MOV 	[R7],R3		; guarda coluna na memoria
	
	MOV		R7,R1		; Tecla premida - guarda o valor da linha 
						; (1,2,4 ou 8) no registo R7
	SHL		R7,8		; Empurra o valor da linha para o byte mais 
						; significativo do registo R7 
						; (0000.0000 0000.0010 -> 0000.0010 0000.0000) 
	ADD		R7,R3		; Adiciona a coluna a R7 fica Byte1,Byte2=L,C
						; (0000.0010 0000.0000 -> 0000.0010 0000.0100) 
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
	;verifica se a tecla tem movimento atribuido
	MOV		R8,R9		; Para nao estragar R9 que contem a tecla
	MOV		R7,tec_def	; R7 = endereço da tabela de atribuicao de tecla
	MOV		R3,4H		; cada tecla esta definida em 2 palavras
	MUL		R8,R3		; para ir para a tecla respect. tenho que saltar
						; 4 bytes * numero da tecla
	ADD		R7,R8		; R7 fica a apontar para a posicao da tabela 
						; correspondente ao movimento que queremos fazer
	MOV		R3,[R7]		; R3 = valor da tecla na tabela
	MOV		R7,ES0_tec
	CMP		R3,R7		; se for igual ao estado zero do teclado, ou
	JZ		rst_estd	; seja, se n estiver atribuida
	JMP		sai_tec
rst_estd:
	MOV		R9,ES0_tec	; R9 = estado 0
	JMP		sai_tec

sai_tec:
	POP		R10
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

; **********************************************************************
; PACMAN
; usa tecla recebida atraves do registo R9
; usa a posicao actual do pacman recebida em R1 (linha) e R2 (coluna)
; actualiza R1 e R2 com a nova posicao, move o pacman e faz o update
; ao estado do teclado
pacman:
	PUSH	R0
	PUSH	R3
	PUSH 	R4
	PUSH	R5
	PUSH	R6
	PUSH	R7
	PUSH	R9
	
	; CONDICOES A VERIFICAR PARA MOVER PACMAN
	; verificacao se o teclado esta ON ou OFF
	MOV		R3,keyb_stt
	MOV		R5,[R3]
	CMP		R5,OFF
	JZ		sai_pac		; Se estiver OFF, nao faz nada e sai da rotina
	
	MOV		R3,ES0_tec	; Se estiver ON, mas R9 estiver no estado 0
	CMP		R9,R3		
	JZ		sai_pac		; sai da rotina sem fazer nada
	
	; TODAS AS CONDICOES VERIFICADAS, PODEMOS MOVER O PACMAN
	MOV		R7,0		; serve para controlar variavel de estado 
						; que controla o limpa ou o desenho
	MOV		R8,pac		; coloca o desenho do pacman em R8
	
	MOV		R0,tec_def	; R0 = apontador para tabela de movimentos
	MOV		R3,4H		; cada tecla esta definida em 2 palavras
	MUL		R9,R3		; para ir para a tecla respect. tenho que saltar
						; 4 bytes * numero da tecla
	ADD		R0,R9		; R0 fica a apontar para a posicao da tabela 
						; correspondente ao movimento que queremos fazer
	
	MOV		R5,[R0]		; R3 = movimento em linha	
	MOV 	R6,[R0+2]	; R4 = movimento em coluna (palavra seguinte)
	
	MOV		R0,des_limp	; R0 = aponta para a variavel de estado da
						; rotina desenha (0 - limpa, 1 - desenha)
	MOV		[R0],R7		; poe a variavel de estado de desenha a limpar
	CALL	desenha		; limpa o desenho actual (apesar de a rotina se 
						; chamar desenha, se a variavel de estado
						; des_limp estiver a 0, a rotina apaga)
	ADD		R1,R5		; movimento em linha: guarda nova posicao em R1
	ADD		R2,R6		; movimento em coluna: guarda nova posicao em R2
	
	; verificacao de jogada	
	CALL	check_move	; chama rotina de verificacao de jogada
	; fim de verificacao de jogada
	MOV		R7,1		;  
	MOV		R0,des_limp	; Altera a variavel de estado de desenha para
	MOV		[R0],R7		; passar a desenhar
	
	CALL 	desenha		; Desenha o pacman na nova posicao
	PUSH 	R1
	PUSH	R4
	MOV		R4,pac_pos	
	SHL		R1,8
	ADD		R1,R2
	MOV		[R4],R1			; coloca a nova pos. do pacman em memoria
	POP		R4
	POP		R1
	MOV		R3,keyb_stt	; Modifica a variavel de estado do teclado para
	MOV		R5,OFF		; nao indicar que uma tecla premida foi aceite
	MOV		[R3],R5		; colocando a veriavel a zero
	
sai_pac:
	POP		R9
	POP		R7
	POP		R6
	POP		R5
	POP		R4
	POP		R3
	POP		R0
	RET
; **********************************************************************
; FANTASMAS
; Recebe apontador relativo para o fantasma a actuar
; guarda-o em R0
; nao muda R0 ate ao final do ciclo
; alternativamente substituimos R0 por uma posicao de memoria

fantasmas:
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
	
	MOV		R0,call_fant
	MOV		R10,[R0]
	MOV		R3,0
	CMP		R10,R3
	JZ		rst_fant
	
	MOV 	R0,fant_stt		; R0 = Apontador para estado do fantasma
	MOVB 	R3,[R0]			; R3 = Estado do fantasma
	MOV 	R4,fant_pos		; R4 = Apontador para posicao do fantasma
	MOVB 	R5,[R4]			; R5 = linha actual do fantasma
	ADD		R4,1			; passa a coluna
	MOVB	R6,[R4]			; R6 = coluna actual do fantasma
	SUB		R4,1			; volta ao apontador original


	; IFs
	CMP		R3,fant_dorme	; Se estiver nao inicializado
	JZ		sai_fant		; sai sem fazer nada

	CMP		R3,fant_acorda 	; Se estiver marcado para inicializar
	JZ		acorda_fant		; vai acordar o fantasma
							; se nao for 0 ou 1, vamos ver se esta na caixa
	CMP		R3,fant_caixa	; Se estiver dentro da caixa
	JLE		saicx_fant		; 2-5 vai mover-se para cima, 6 sai da caixa

	CMP		R3,fant_jogo	; Se estiver fora da caixa, esta em jogo
	JZ		move_fant		; vai mover-se na direccao do pacman
	
	CMP		R3,fant_jogo	; Se estiver bloqueado e diametralmente 
	JGT		desbloq_fant	; oposto ao pacman (estado 7 ou 8)
		
	
desbloq_fant:
	CALL desbloqueia
	JMP		rst_fant

acorda_fant:
	PUSH	R1				; preservar linha e coluna do pacman nos
	PUSH	R2				; registos R1 e R2
	MOV 	R1,fant_lin		; coloca a linha inicial do fantasma em R1
	MOV 	R2,fant_col		; coloca a coluna inicial do fantasma em R2
	MOV 	R8,fant		 	; coloca o desenho do fantasma em R8
	CALL	desenha			; desenha o fantasma com R1, R2 e R8
	SHL		R1,8
	ADD		R1,R2
	MOV		[R4],R1			; coloca a posicao do fantasma em memoria
	POP		R2
	POP		R1
	
	ADD		R3,1
	MOVB 	[R0],R3			; actualiza o estado do fantasma
	JMP		rst_fant 		;

saicx_fant:

	PUSH	R0
	PUSH	R1				; preservar linha e coluna do pacman nos
	PUSH	R2				; registos R1 e R2
	MOV		R1,R5
	MOV		R2,R6
	MOV		R7,0			; serve para controlar variavel de estado 
							; que controla o limpa ou o desenho
	MOV 	R8,fant		 	; coloca o desenho do fantasma em R8
	MOV		R0,des_limp	; R0 = aponta para a variavel de estado da
						; rotina desenha (0 - limpa, 1 - desenha)
	MOV		[R0],R7		; poe a variavel de estado de desenha a limpar
	CALL	desenha		; limpa o desenho actual (apesar de a rotina se 
						; chamar desenha, se a variavel de estado
						; des_limp estiver a 0, a rotina apaga)
	SUB		R1,1		; move-se na direccao da saida
	MOV		R7,1		; 
	MOV		R0,des_limp	; Altera a variavel de estado de desenha para
	MOV		[R0],R7		; passar a desenhar
	
	CALL 	desenha		; Desenha o fantasma na nova posicao
	
	SHL		R1,8
	ADD		R1,R2
	MOV		[R4],R1			; coloca a nova pos. do fantasma em memoria
	POP		R2
	POP		R1
	POP		R0

	ADD		R3,1			; 
	MOVB 	[R0],R3			; actualiza o estado do fantasma
	CMP		R3,fant_caixa	; verifica se ainda esta na caixa
	JGT		avisa			; se ja saiu da caixa
	JMP		rst_fant 		;

avisa:
;	MOV						; avisa que outro fantasma pode ser acordado
	JMP		rst_fant


move_fant:
	CALL	GO				;move fantasma e poe nova posicao em memoria

rst_fant:
	MOV		R0,call_fant
	MOV		R3,0
	MOV		[R0],R3
	JMP		sai_fant
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
; *********************************************************************
; *********************************************************************
GO:
	PUSH	R0
	PUSH	R1				; preservar linha e coluna do pacman nos
	PUSH	R2				; registos R1 e R2
	PUSH	R3
	PUSH	R4
	PUSH	R5
	PUSH	R6
	PUSH	R7
	PUSH	R8
	PUSH	R9
	PUSH	R10
	
	CALL	fant_calc	;

	; neste ponto R1 e R2 contem o que e preciso somar a R5 e R6 para
	; mover o fantasma. vamos trocar R1 com R5 e R2 com R6 para usarmos 
	; os registos R1 e R2 para a rotina de desenho.
	SWAP	R1,R5
	SWAP	R2,R6
	
	CALL	apaga_fant	;
	
	ADD		R1,R5		; move-se na direccao do pacman
	ADD		R2,R6		; move-se na direccao do pacman
	;para verificar se houver mesmo movimento mais a frente
	MOV 	R0,R1		; guarda valor de R1 em R0 para usar a frente
	MOV		R7,R2		; guarda valor de R2 em R7 para usar a frente
	CALL	check_move	; chama rotina de verificacao de jogada
	MOV		R4,move_ok
	MOV		R3,[R4]
	CMP		R3,0
	JNZ		fant_bloq
	CALL	desenha_fant; se tudo correu bem
	JMP		sai_GO
fant_bloq:	
	CALL	chk_bloq	; se nao pode mover, verifica a condicao de bloq
	MOV		R8,panic
	MOV		R9,[R4]
	CMP		R9,R8		; se estiver diametalmente oposto ao pacman
	JNZ		fant_retry_lin ; move linha ou coluna
						; senao passa ao estado 7 ou 8
							; e espera ser desbloqueado
	CALL	desenha_fant	;entretanto desenha no mesmo sitio
	JMP		sai_GO
	
fant_retry_lin:	
	MOV		R1,R0		; experimentar a mover so na linha		
	CALL	check_move	; tenta outra vez
	MOV 	R3,[R4]
	CMP		R3,0
	JNZ		fant_retry_col
	CALL	desenha_fant
	JMP		sai_GO
	
fant_retry_col:
	MOV		R2,R7		; repoe valor de coluna
	CALL	check_move	; tenta outra vez
	MOVB	R3,[R4]
	CMP		R3,0
	JNZ		sai_GO
	CALL	desenha_fant	
	JMP		sai_GO

sai_GO:
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
;**********************************************************************
fant_calc:

calc_linha:
	CMP 	R1,R5 		; diferenca entre linha do fantasma e do pacman
	JZ		msm_linha
	JN		neg_linha
	JMP		pos_linha
msm_linha:
	MOV		R1,0
	JMP		calc_col
neg_linha:
	MOV		R1,-1
	JMP		calc_col
pos_linha:
	MOV		R1,1
	JMP		calc_col
	
calc_col:
	CMP 	R2,R6		; diferenca entre coluna do fantasma e do pacman
	JZ		msm_col
	JN		neg_col
	JMP		pos_col
msm_col:
	MOV		R2,0
	JMP		out
neg_col:
	MOV		R2,-1
	JMP		out
pos_col:
	MOV		R2,1
	JMP		out

out:
	RET
	
;**********************************************************************	
apaga_fant:
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
	
	MOV		R7,0			; serve para controlar variavel de estado 
							; que controla o limpa ou o desenho
	MOV 	R8,fant		 	; coloca o desenho do fantasma em R8
	MOV		R0,des_limp	; R0 = aponta para a variavel de estado da
						; rotina desenha (0 - limpa, 1 - desenha)
	MOV		[R0],R7		; poe a variavel de estado de desenha a limpar
	CALL	desenha		; limpa o desenho actual (apesar de a rotina se 
						; chamar desenha, se a variavel de estado
						; des_limp estiver a 0, a rotina apaga)
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

; *********************************************************************
desenha_fant:
	PUSH	R0
	PUSH	R4
	PUSH	R7
	PUSH	R8
	PUSH	R9
	PUSH	R10
	
	MOV 	R8,fant		 	; coloca o desenho do fantasma em R8
	MOV		R7,1		; 
	MOV		R0,des_limp	; Altera a variavel de estado de desenha para
	MOV		[R0],R7		; passar a desenhar
	
	CALL 	desenha		; Desenha o fantasma na nova posicao
	
	SHL		R1,8
	ADD		R1,R2
	MOV 	R4,fant_pos
	MOV		[R4],R1		; coloca a nova pos. do fantasma em memoria
	
	POP		R10
	POP		R9
	POP		R8
	POP		R7
	POP		R4
	POP		R0
	
	RET	
;**********************************************************************

	
; *********************************************************************	
; DESBLOQUEIA FANTASMA
; R5 (linha) e R6 (coluna) em que o fantasma se encontra  
; R3: estado do fantasma, 
desbloqueia:
	PUSH	R0
	PUSH	R1
	PUSH	R2
	PUSH	R3
	PUSH 	R4
	PUSH	R7
	PUSH	R8
	PUSH	R9
	PUSH	R10
	
			
	MOV		R9,desbl_cont 	; contador
	MOV		R1,fant_act		; fantasma actual
	MOV		R2,[R1]
	ADD		R9,R2
	MOV		R10,[R9]		; valor do contador
	AND		R10,R10			;actualizar flags
	JNZ		desloca
	CALL	desbl_init
	
desloca:
	MOV		R1,R5
	MOV		R2,R6		;coloca linha e coluna em R5 e R6
	
	CALL	apaga_fant	; apaga o fantasma na posicao actual

	MOV		R9,fant_desbl 
	MOV		R0,fant_act
	MOV		R8,[R0]
	ADD		R9,R8		
	MOV		R3,[R9]		; movimento linha
	ADD		R9,2
	MOV		R4,[R9]		; movimento coluna

	ADD		R1,R3		; desloca-se na direccao que foi definida
	ADD		R2,R4		; 

	CALL	desenha_fant
	
	MOV		R9,desbl_cont 
	MOV		R8,[R0]
	ADD		R9,R8		
	MOV		R10,[R9]	; numero de iteracoes ate chegar ao fim
	SUB		R10,1		; menos uma
	MOV		[R9],R10	; actualiza o contador em memória
	CMP		R10,0		;ja chegou ao fim?
	JZ 		rst_desbloqueia
	JMP		sai_desbloqueia
							
rst_desbloqueia:
	MOV 	R0,fant_stt
	MOV		R3,fant_act
	MOV		R4,[R3]
	ADD		R0,R4			; R0 aponta para o estado do fantasma actual
	MOV		R3,fant_jogo
	MOVB	[R0],R3	; coloca estado a 6 - em jogo

sai_desbloqueia:	
	POP		R10
	POP		R9
	POP		R8
	POP		R7
	POP		R4
	POP		R3
	POP		R2
	POP		R1
	POP		R0
	RET

; *********************************************************************
desbl_init:
	MOV		R7,caixa_lin	; R7 = limite superior da caixa
	MOV		R0,nlin_cx		; numero de linhas da caixa
	MOV		R8,caixa_lin
	ADD		R8,1
	ADD		R8,R0			; R8 = limite inferior da caixa
	
	MOV 	R9,caixa_col	; R9 = limite esquerdo da caixa
	MOV		R0,ncol_cx		; numero de linhas da caixa
	MOV		R10,caixa_col
	;ADD		R10,1
	ADD		R10,R0			; R10 = limite direito da caixa
	
	MOV		R0,nlin_def		; para criar um buffer em cima
	SUB		R7,R0			; buffer criado
	SUB		R7,1
	MOV		R0,ncol_def		; para criar um buffer a esquerda
	SUB		R9,R0   		; buffer criado

	MOV		R2,fant_bloq_1	;bloqueado em cima
	CMP		R2,R3			;e esse o estado?
	JZ		desloca_hor	
	JMP		desloca_ver

desloca_hor:
	MOV		R1,R6
	SUB		R1,R9		; distancia a esquerda
	MOV		R2,R6
	SUB		R2,R10		; distancia a direita
	NEG		R2			; distancia tem que ser positiva
	CMP		R1,R2		; qual a distancia mais curta?
	JLT		desloca_esq;
	JGT		desloca_dir;
	JZ		desloca_esq;
desloca_esq:
	MOV		R10,R1
	MOV		R3,0
	MOV		R4,-1
	JMP sai_desbl_init
desloca_dir:
	MOV		R10,R2
	MOV		R3,0
	MOV		R4,1
	JMP sai_desbl_init

desloca_ver:
	MOV		R1,R5
	SUB		R1,R7		; distancia a cima
	MOV		R2,R5
	SUB		R2,R8		; distancia a baixo
	NEG		R2			; distancia tem que ser positiva
	CMP		R1,R2		; qual a distancia mais curta?
	JLT		desloca_cim;
	JGT		desloca_bai;
	JZ		desloca_bai;
desloca_cim:
	MOV		R10,R1
	MOV		R3,-1
	MOV		R4,0
	JMP sai_desbl_init
desloca_bai:
	MOV		R10,R2
	MOV		R3,1
	MOV		R4,0
	JMP sai_desbl_init

sai_desbl_init:
	MOV		R0,fant_act
	MOV		R8,[R0]
	MOV		R9,desbl_cont
	ADD		R9,R8			; para cada fantasma coloca
	MOV		[R9],R10		; o valor total do deslocamento em memoria
	MOV		R9,fant_desbl
	ADD		R9,R8
	MOV		[R9],R3			; para cada fantasma
	ADD		R9,2
	MOV		[R9],R4		; coloca o deslocamento em memoria 
							
	
	
	RET
; *********************************************************************


; **********************************************************************
; CONTROLO	
controlo:
	; restart?
	MOV		R0,rstrt
	CMP		R9,R0
	JNZ		sai_ctrl
	MOV		SP,fim_pilha; incializa SP
	MOV		R9,ES0_tec	; Coloca teclado no estado 0
	JMP		init
sai_ctrl:
	RET

; **********************************************************************
; GERADOR
gerador:

sai_ger:
	RET
	
; **********************************************************************
; ROTINAS AUXILIARES
; **********************************************************************
; LIMPA ECRA
limpa:
	PUSH 	R0
	PUSH	R1
	PUSH	R3
	MOV		R0,base		; Inicio do pixelscreen (canto superior esq)
	MOV		R1,topo		; Fim do pixelscreen (canto inferior dir)
	MOV		R3,0		; R3 = 0
limpa_c:		
	MOV		[R0],R3		; Coloca o endereço a zero = limpa o pixel
	ADD		R0,2		; Passa ao pixel seguinte
	CMP		R0,R1		; Verifica se já chegou ao fim do pixelscreen
	JNE		limpa_c		; Se nao, passa ao pixel seguinte e limpa
	POP		R3
	POP		R1
	POP		R0
	RET
;
;
;
; **********************************************************************
; DESENHA (OU APAGA)
; Recebe a localizacao do desenho (canto superior esquerdo)
; em R1, R2 (linha, coluna)
; em R8 recebe o desenho
; nao retorna nada
; desenha um objecto ou apaga-o, consoante a variável de estado indicar
desenha:
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
;INICIALIZACOES

	MOV 	R3,R2		; Coluna auxiliar - R2 vai ser destruido
	MOV		R6,nlin
	MOV		R4,[R6]		; R4 - N linhas do desenho
	MOV		R6,ncol
	MOV		R5,[R6]		; R5 - N colunas do desenho
	MOV		R10,8		; para ir para o fim da tabela de mascaras

;DECISAO DO PIXEL A ACENDER
	MOV 	R6,mascaras	; R6: ponteiro para o primeiro byte de mascaras
	ADD		R6,R10		; Vai para o fim da tabela de mascaras (R5=8)
	SUB		R6,R5		; Subtrai o numero de colunas do desenho
						; para ficar a apontar para a posicao certa
	MOVB 	R7,[R6]		; R7: primeiro valor de mascara
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
	CMP		R10,R4		; Ja passou da ultima linha do desenho?
	JZ		sai_des 	; Se ja passou da ultima linha, vai para fim
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
						
sai_des:		
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
	
; ROTINA ACENDE PIXEL -- Chamada com R1 = linha e R2 = coluna. 
; R1 e R2 variam entre 0 e 31.
acende:					
	;pushs
	PUSH	R0
	PUSH	R1
	PUSH	R2
	PUSH	R3
	PUSH	R4
	PUSH	R5
	PUSH	R6
	PUSH	R7
	PUSH	R8
	MOV		R0,base		; R0: endereco de base do pixelscreen
	MOV		R4,4		; Inicializacao de valores usados em acende
	MOV		R5,8		; Inicializacao de valores usados em acende
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
	
	MOV		R0,des_limp
	MOV		R3,[R0]		; vai ver o que tem na variavel de estado do des 
	CMP		R3,0		; se for zero, esta no modo apagar
	JZ		apaga_pixel	; salta para apaga pixel. caso contrario segue
acende_pixel:
	MOVB	R8,[R1]		; Vai buscar os bits que ja estao acesos
	OR		R7,R8		; Junta o anterior ao bit que queremos acender
	MOVB	[R1],R7		;acende o bit em questao, deixando inalterado os
						; bits ja acesos dentro do byte	
	JMP 	pops
apaga_pixel:			
	MOVB	R8,[R1]		; Vai buscar os bits que ja estao acesos
	SUB		R8,R7
	MOVB	[R1],R8		;acende o bit em questao, deixando inalterado os
						; bits ja acesos dentro do byte		
	;pops
pops:
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
	
; **********************************************************************
; DESENHA ECRA
; Nao recebe nem retorna argumentos
; Desenha as barreiras do ecra e a caixa central
desenha_ecra:	
	PUSH	R0
	PUSH	R1
	PUSH	R2
	PUSH	R3
	PUSH	R4
	PUSH	R5
	PUSH	R6
	PUSH	R8
	
	; desenha barreiras
	; desenha barreira superior e inferior
	MOV		R0,base		; inicio da linha superior
	MOV		R3,mask_linha	
	MOV		[R0],R3		; Coloca a linha superior a 1 (metade)
	MOV		[R0+2],R3	; Coloca a linha superior a 1 (metade)
	MOV		R0,topo		; fim de linha inferior
	MOV		R3,mask_linha	
	MOV		[R0-2],R3	; Coloca a linha inferior a 1 (metade)
	MOV		[R0-4],R3	; Coloca a linha inferior a 1 (metade)
	
	; desenha barreiras laterais
	; esquerda
	MOV		R0,base	
	ADD		R0,4	 	; comeca aqui, canto superior esquerdo
	MOV		R4,topo		;
	SUB		R4,4		; acaba aqui, canto inferior esquerdo
	MOV		R3,mask_colE;
b_e:
	MOV		[R0],R3		; acende pixel a 1 na extremidade
	ADD		R0,4		; passa a linha seguinte
	CMP		R0,R4		; ja chegou ao fim?
	JNZ		b_e			; se nao, volta a iterar
	; direita
	MOV		R0,base	
	ADD		R0,6	 	; comeca aqui, canto superior direito
	MOV		R4,topo		;
	SUB		R4,2		; acaba aqui, canto inferior direito
	MOV		R3,mask_colD;
b_d:
	MOV		[R0],R3		; acende pixel a 1 na extremidade
	ADD		R0,4		; passa a linha seguinte
	CMP		R0,R4		; ja chegou ao fim?
	JNZ		b_d			; se nao, volta a iterar
	
	; desenha caixa central de onde saem os fantasmas
	; coloca as dimensoes linha e coluna da caixa
	MOV		R5,nlin		; R5 = endereco de numero de linhas a usar pela
						; rotina de desenho
	MOV		R6,nlin_cx	; R6 = numero de linhas que a caixa vai ter
	MOV		[R5],R6		; coloca o numero de linhas da caixa no endereco
						; apontado por R5, que corresponde a nlin
	MOV		R5,ncol		; R5 = endereco de numero de colunas a usar pela
						; rotina de desenho
	MOV		R6,ncol_cx	; R6 = numero de colunas que a caixa vai ter
	MOV		[R5],R6		; coloca o num. de colunas da caixa no endereco
						; apontado por R5, que corresponde a ncol
		
	MOV		R1,caixa_lin ; R1 = canto da caixa para usar "desenho"
	MOV		R2,caixa_col ; R2 = canto da caixa para usar "desenho"
	MOV		R8,caixa	 ; R8 =  desenho da caixa
	CALL 	desenha		 ; desenha a caixa
	
	MOV		R5,nlin		
	MOV		R6,nlin_def  ; numero de linhas originalmente em nlin
	MOV		[R5],R6		
	MOV		R5,ncol
	MOV		R6,ncol_def	 ; numero de colunas originalmente em ncol
	MOV		[R5],R6
		
	POP		R8
	POP		R6
	POP		R5
	POP		R4
	POP		R3
	POP		R2
	POP		R1
	POP		R0
	RET

; **********************************************************************
; INCREMENTA CONTADOR DE TEMPO
; Nao recebe nem retorna argumentos
; Incrementa o contador de tempo uma unidade
; accionado por rotina de interrupcao sig0
conta:
	PUSH	R0
	PUSH	R1
	PUSH	R2
	PUSH	R3
	PUSH	R4
	PUSH	R5
	
	MOV		R0,conta_tempo	;vai buscar a variavel de contagem
	MOV		R1,[R0]			; ve o seu valor
	AND		R1,R1
	JZ		sai_conta	; se for zero, sai, se for 1 conta!
	
	MOV		R3,0AH		; ver se chegou a XA -> para contagem decimal
	MOV		R5,000FH	; mascara para isolar o XXXAH
	MOV		R0,POUT1	; R0 = endereco do Periferico de saida 1
	MOV		R1,contador ; R1 = apontador para contador
	MOVB	R2,[R1]		; R2 =  o valor actual de contagem em memoria
	ADD		R2,1		; soma uma unidade ao valor de contagem
	MOV		R4,R2		;
	AND		R4,R5		; isola o ultimo nibble
	CMP		R4,R3		; chegou a A no ultimo nibble?
	JNZ		check_A0	; se nao chegou, vai ver se chegou a A0
	ADD		R2,6		; se ja chegou a 10, conta em modo decimal 
check_A0:	
	;se chegou ao A0, recomeça do 00
	MOV		R4,0A0H
	CMP		R2,R4
	JNZ		incr_cont	; se ainda nao chegou ao A0, conta normalmente
	MOV		R2,00H		; se ja chegou ao A0, recomeca do 00
incr_cont:
	MOVB	[R0],R2		; coloca no display a contagem actual
	MOVB	[R1],R2		; coloca na memoria a contagem actual
	
	;se chegou ao 99, recomeça
	

sai_conta:
	MOV		R0,conta_tempo
	MOV		R1,0H
	MOV		[R0],R1			; poe a variavel de contagem a zero outra x
	POP		R5
	POP		R4
	POP		R3
	POP		R2
	POP		R1
	POP		R0
	RET

; **********************************************************************
; CHECK MOVE
; Rotina de verificacao de movimento do pacman/fantasma.
; Deve ser chamada de cada vez que um destes elementos quer fazer um
; movimento. Verifica se o movimento e valido ou nao.
; Recebe a posicao para onde o elemento se quer mover nos registos 
; R1 (linha) e R2 (coluna).  Usa tb R5 e R6
; se nao puder mover os objectos, subtrai o deslocamento de R1 e R2
check_move:
	PUSH	R0
	PUSH	R3
	PUSH 	R4
	PUSH	R7
	PUSH	R8
	PUSH	R9
	PUSH	R10
	
	MOV		R7,R1
	MOV		R8,R2
	
	; perimetro de jogo
	MOV		R0,0H		; barreira superior/esquerda
	MOV		R3,20H		; barreira inferior/direita
	
	; barreira superior
	CMP		R7,R0
	JZ		output_N
	
	; barreira inferior
	MOV		R9,nlin		; apontador do numero de linhas do desenho
	MOV		R10,[R9]		; numero de linhas do desenho
	ADD		R7,R10		; soma o numero de linhas a 1a linha do desenho
	CMP		R7,R3		
	JZ		output_N
	
	; barreira esquerda
	CMP		R8,R0
	JZ		output_N
		
	; barreira direita
	MOV		R9,ncol		; apontador do numero de colunas do desenho
	MOV		R10,[R9]	; numero de linhas do desenho
	ADD		R8,R10		; soma o numero de colunas a 1a col. do desenho
	CMP		R8,R3
	JZ		output_N

; verificacao do bloqueio contra a caixa central
chk_cx:
	MOV		R7,caixa_lin	; R7 = limite superior da caixa
	MOV		R0,nlin_cx		; numero de linhas da caixa
	MOV		R8,caixa_lin
	ADD		R8,R0			; R8 = limite inferior da caixa
	
	MOV 	R9,caixa_col	; R9 = limite esquerdo da caixa
	MOV		R0,ncol_cx		; numero de linhas da caixa
	MOV		R10,caixa_col
	ADD		R10,R0			; R10 = limite direito da caixa
; verificar posicionamento vertical
chk_vertical:	
	MOV		R0,nlin_def		; para criar um buffer em cima
	SUB		R7,R0			; buffer criado
	CMP		R1,R7			; compara posicao com barreira superior
	JLE		output_Y		; se estiver acima do limite sup c/ buffer
	CMP		R1,R8			; compara posicao com barreira inferior
	JGE		output_Y		; Se estiver abaixo do limite inferior
; verificar posicionamento horizontal
chk_horizontal:
	MOV		R3,ncol_def		; para criar um buffer a esquerda
	SUB		R9,R3			; buffer criado
	CMP		R2,R9			; compara posicao com barreira esquerda
	JLE		output_Y		; se esta a esquerda do limite esq. c/buffer		
	CMP		R2,R10			; compara posicao com barreira direita
	JGE		output_Y		; se esta a direita do limite dir. s/buffer
	JMP		output_N		; esta a querer ir para cima da caixa.
							; nao autorizado.
output_N:
	MOV		R3,move_ok
	MOV		R4,1			; nao pode mover
	MOV		[R3],R4
	SUB		R1,R5			; volta linha e coluna original
	SUB		R2,R6
	JMP		sai_check_move

output_Y:
	MOV		R3,move_ok
	MOV		R4,0			; pode mover
	MOV		[R3],R4
	JMP		sai_check_move

sai_check_move:	
	POP		R10
	POP		R9
	POP		R8
	POP		R7
	POP		R4
	POP		R3
	POP		R0
	RET


; **********************************************************************
; **********************************************************************
; CHK BLOQ - verifica onde e que o fantasma esta bloqueado
; **********************************************************************
; sabemos que o fantasma esta bloqueado na caixa central
; verificacao do local de bloqueio
chk_bloq:
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
	
	; por limites da caixa dos registos
	MOV		R7,caixa_lin	; R7 = limite superior da caixa
	MOV		R0,nlin_cx		; numero de linhas da caixa
	MOV		R8,caixa_lin
	ADD		R8,R0			; R8 = limite inferior da caixa
	MOV 	R9,caixa_col	; R9 = limite esquerdo da caixa
	MOV		R0,ncol_cx		; numero de linhas da caixa
	MOV		R10,caixa_col
	ADD		R10,R0			; R10 = limite direito da caixa
	MOV		R0,nlin_def		; para criar um buffer em cima
	SUB		R7,R0			; buffer criado
	MOV		R3,ncol_def		; para criar um buffer a esquerda
	SUB		R9,R3			; buffer criado
	
	CMP		R1,R7
	JZ		bloq_cima
	CMP		R1,R8
	JZ		bloq_baixo
	CMP		R2,R9
	JZ		bloq_esq
	CMP		R2,R10
	JZ		bloq_dir

bloq_cima:
bloq_baixo:
	;SUB		R1,R5			; linha fica constante
	MOV		R0,pac_pos		; busca apontador para posicao do pacman
	MOVB	R3,[R0]			; linha do pacman
	ADD		R0,1
	MOVB	R4,[R0]			; coluna do pacman
	CMP		R2,R4			; compara coluna: fantasma (R2)/pacman (R4)
	JZ		bloq_total_1	; diametralmente oposto ao pacman
	JMP		sai_chk_bloq		

bloq_esq:
bloq_dir:
	;SUB		R2,R6			; coluna fica constante
	MOV		R0,pac_pos		; busca apontador para posicao do pacman
	MOVB	R3,[R0]			; linha do pacman
	CMP		R1,R3			; compara linha: fantasma (R2)/pacman (R4)
	JZ		bloq_total_2	; diametralmente oposto ao pacman
	JMP		sai_chk_bloq		
	
bloq_total_1:
	MOV 	R0,fant_stt		; busca apontador para estado dos fantasmas
	MOV		R3,fant_act		; busca fantasma actual
	MOV		R4,[R3]
	ADD		R0,R4			; R0 aponta para o estado do fantasma actual
	MOV		R3,fant_bloq_1
	MOVB 	[R0],R3			; coloca estado a 7 bloqueado em cima/baixo
							; na proxima iteracao vai para a rotina de
							; desbloqueio
	MOV		R0,move_ok
	MOV		R3,2
	MOV 	[R0],R3
	JMP		sai_chk_bloq
	
bloq_total_2:
	MOV 	R0,fant_stt		; busca apontador para estado dos fantasmas
	MOV		R3,fant_act		; busca fantasma actual
	MOV		R4,[R3]
	ADD		R0,R4			; R0 aponta para o estado do fantasma actual
	MOV		R3,fant_bloq_2
	MOVB 	[R0],R3			; coloca estado a 8 bloqueado em esq/dir
							; na proxima iteracao vai para a rotina de
							; desbloqueio
	MOV		R0,move_ok
	MOV		R3,2
	MOV		[R0],R3
	JMP		sai_chk_bloq

sai_chk_bloq:
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

; **********************************************************************
; **********************************************************************
; ROTINAS DE INTERRUPCAO
; **********************************************************************
; **********************************************************************
; sig0: conta tempo
sig0:
	PUSH	R0
	PUSH	R3
	MOV		R0,conta_tempo
	MOV		R3,1
	MOV		[R0],R3
	POP		R3
	POP		R0
	RFE
	
; **********************************************************************
; sig1: move fantasma
sig1:
	PUSH	R0
	PUSH	R3
	MOV		R0,call_fant
	MOV		R3,1
	MOV		[R0],R3
	POP		R3
	POP		R0
	RFE


