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
POUT2	EQU	0C000H	; endereço do porto de E do teclado
POUT3	EQU	06000H	; endereço do porto de E do display hexa extra
MASK	EQU	10H		; mascara para ver se ja saimos do teclado
ES0_tec EQU	0FFH	; estado zero do teclado. pode receber novo comando
cima	EQU	1H		;
baixo	EQU	9H
esq		EQU	4H
dir		EQU	6H
ciesq	EQU	0H
cidir	EQU	2H
baesq	EQU	8H
badir	EQU	0AH
rstrt	EQU	0CH
;
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
pilha:		TABLE 200H		; espaço reservado para a pilha 
fim_pilha:				

; **********************************************************************
; * Dados
; **********************************************************************
PLACE		2400H
; tabela de mascaras a usar pela rotina shape_draw:
; desenhos podem ser modificados
; tamanho maximo: 7x7
mascaras:	STRING	80H,40H,20H,10H,08H,04H,02H,01H	
pac		:	STRING	7H,4H,7H	; desenho do pacman				
fant	: 	STRING	5H,2H,5H	; desenho do fantasma
obj		:	STRING 	2H,7H,2H	; desenho do objecto
caixa	:	STRING	63H,41H,41H,41H,41H,41H,7FH
nlin	:	WORD	3H
ncol	:	WORD	3H
nlin_def	EQU	3H
ncol_def	EQU	3H
nlin_cx		EQU	7H
ncol_cx		EQU	7H
pac_ini_L	EQU 1AH				; linha inicial do pacman
pac_ini_C	EQU 0DH				; coluna inicial do pacman
obj_L1		EQU	1H
obj_L2		EQU	1CH
obj_C1		EQU	2H
obj_C2		EQU	1BH

PLACE		2600H
; variaveis
ON			EQU	1H
OFF			EQU	0H
keyb_stt:	WORD	1H ;(1 - ON, 0 - OFF)
keyb_lin:	WORD	1H
keyb_col:	WORD	1H
des_limp:	WORD	1H ;(1 - desenha, 0 - limpa)

; **********************************************************************
; Tabela de vectores de interrupção
;tab:		WORD	sig0
;			WORD	sig1

PLACE		0H	
	MOV		SP,fim_pilha; incializa SP
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
	POP	R2
	POP R1
	
ciclo:
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
pacman:
	PUSH	R0
	PUSH	R3
	PUSH	R5
	PUSH	R7
	
	; CONDICOES A VERIFICAR PARA MOVER PACMAN
	; verificacao se o teclado esta ON ou OFF
	MOV		R3,keyb_stt
	MOV		R5,[R3]
	CMP		R5,OFF
	JZ		sai_pac		; Se estiver OFF, nao faz nada e sai da rotina
	
	MOV		R3,ES0_tec	; Se estiver ON, mas R9 estiver no estado 0
	CMP		R9,R3		
	JZ		sai_pac		; sai da rotina sem fazer nada
	
	; verificacao do estado do pacman
	; encostado à esquerda = 1000 0000
	; encostado à direita = 0001 0000
	; encostado acima = 0000 1000
	; encostado abaixo = 0000 0001
	; por implementar
	
	; TODAS AS CONDICOES VERIFICADAS, PODEMOS MOVER O PACMAN
	MOV		R7,0		; serve para controlar variavel de estado a limp
	MOV		R8,pac

						; movimento para cima
	MOV		R0,cima
	CMP		R9,R0
	JZ		mov_cima
						; movimento para baixo
	MOV		R0,baixo
	CMP		R9,R0
	JZ		mov_baixo
						; movimento para a esquerda
	MOV		R0,dir
	CMP		R9,R0
	JZ		mov_dir
						; movimento para a direita
	MOV		R0,esq
	CMP		R9,R0
	JZ		mov_esq
						; movimento para cima e esquerda
	MOV		R0,ciesq
	CMP		R9,R0
	JZ		mov_ciesq
						; movimento para cima e direita
	MOV		R0,cidir
	CMP		R9,R0
	JZ		mov_cidir
						; movimento para baixo e esquerda
	MOV		R0,baesq
	CMP		R9,R0
	JZ		mov_baesq
						; movimento para baixo e direita
	MOV		R0,badir
	CMP		R9,R0
	JZ		mov_badir
	
	JMP 	sai_pac

mov_cima:
	MOV		R0,des_limp
	MOV		[R0],R7		; poe a variavel de controle do desenha a limpar
	CALL	desenha		; limpa o desenho actual
	SUB 	R1,1
	CALL	go
	JMP		sai_pac	
mov_baixo:
	MOV		R0,des_limp
	MOV		[R0],R7		; poe a variavel de controle do desenha a limpar
	CALL	desenha		; limpa o desenho actual
	ADD 	R1,1
	CALL	go
	JMP		sai_pac	
mov_dir:
	MOV		R0,des_limp
	MOV		[R0],R7		; poe a variavel de controle do desenha a limpar
	CALL	desenha		; limpa o desenho actual
	ADD 	R2,1
	CALL	go
	JMP		sai_pac	
mov_esq:
	MOV		R0,des_limp
	MOV		[R0],R7		; poe a variavel de controle do desenha a limpar
	CALL	desenha		; limpa o desenho actual
	SUB 	R2,1
	CALL	go
	JMP		sai_pac
mov_ciesq:
	MOV		R0,des_limp
	MOV		[R0],R7		; poe a variavel de controle do desenha a limpar
	CALL	desenha		; limpa o desenho actual
	SUB		R1,1
	SUB 	R2,1
	CALL	go
	JMP		sai_pac
mov_cidir:
	MOV		R0,des_limp
	MOV		[R0],R7		; poe a variavel de controle do desenha a limpar
	CALL	desenha		; limpa o desenho actual
	SUB 	R1,1
	ADD		R2,1
	CALL	go
	JMP		sai_pac
mov_baesq:
	MOV		R0,des_limp
	MOV		[R0],R7		; poe a variavel de controle do desenha a limpar
	CALL	desenha		; limpa o desenho actual
	ADD 	R1,1
	SUB		R2,1
	CALL	go
	JMP		sai_pac
mov_badir:
	MOV		R0,des_limp
	MOV		[R0],R7		; poe a variavel de controle do desenha a limpar
	CALL	desenha		; limpa o desenho actual
	ADD		R1,1
	ADD 	R2,1
	CALL	go
	JMP		sai_pac
go:	
	MOV		R7,1		; server para por a variavel de estado a desenh
	MOV		R0,des_limp
	MOV		[R0],R7		; poe a variavel de controle do desenha a desenh
	CALL 	desenha
	MOV		R3,keyb_stt	; Quando a deixar de estar premida,
	MOV		R5,OFF		; Faz o update do estado do teclado para OFF
	MOV		[R3],R5
	RET
	
sai_pac:
	POP		R7
	POP		R5
	POP		R3
	POP		R0
	RET
; **********************************************************************
; FANTASMAS
fantasmas:

sai_fant:
	RET

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
;
;tem que passar a receber em R tambem o n linhas e n colunas pq os 
;desenhos podem ter isto diferente
; **********************************************************************
; DESENHA
; Recebe a localizacao do desenho (canto superior esquerdo)
; em R1, R2 (linha, coluna)
; em R8 recebe o desenho
; nao retorna nada
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
	MOV		R5,nlin
	MOV		R6,nlin_cx
	MOV		[R5],R6
	MOV		R5,ncol
	MOV		R6,ncol_cx
	MOV		[R5],R6
		
	MOV		R1,caixa_lin
	MOV		R2,caixa_col
	MOV		R8,caixa
	CALL 	desenha
	
	MOV		R5,nlin
	MOV		R6,nlin_def
	MOV		[R5],R6
	MOV		R5,ncol
	MOV		R6,ncol_def
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
