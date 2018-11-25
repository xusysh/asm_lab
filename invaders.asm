[BITS 16]
[SEGMENT .text]

Start       dw      init_carte_video
SegVal	    dw	    0
Version     dw      1
Signature   db      "xusysh",0,"           "

init_carte_video: ;init video card
	mov ax,cs
	mov ds,ax
	mov ax,13h
	int 10h
	mov ax,0a000h
	mov es,ax

;init_sprite_aliens: ;pour les deux tableaux d'aliens
	;mov bx, 0
	;push bx

init_vitesse: ;init vitesse jeu
	mov ax,[vitesse_initiale] ;compteur de vitesse initiale
	mov [vitesse],ax ;compteur de vitesse du jeu

affichage_textscore: ;affichage texte "score"
	mov word [x],20
	mov word [y],10
	mov word [add_sprite],textscore
	mov word [l],29
	mov word [h],5
	call affiche_sprite

	;initialise les tableaux d'aliens
	call init_tab

boucle: ;boucle principale
	;affichage du vaisseau
	mov dx,[xv]
	mov word [x],dx
	mov dx,[yv]
	mov word [y],dx
	mov word [add_sprite],vaisseau
	mov word [l],15
	mov word [h],7
	call affiche_sprite

	;décremente et teste le compteur de vitesse jeu pour l'affichage des aliens
	dec word [vitesse]
	cmp word [vitesse],0
	je affiche_aliens

	;incremente compteur de cycle du tire (vitesse tire) relativement avec le compteur de vitesse jeu
	inc word [vitesse_tir]
	cmp word [vitesse_tir],50
	je test_tir

	jmp appuie_touche

	test_tir:
		;si tir n'a pas encore touché d'alien
		cmp word [tir_OK],1
		je test_tir_OK
		jmp appuie_touche
		test_tir_OK:
			call affiche_tir
			call test_explosion
		jmp appuie_touche

	affiche_aliens: ;appelle la routine d'affichage des aliens
		call affichage_aliens

	deplace_alien: ;gestion du déplacement des aliens
		cmp word [xa1],90
		je change_sens
		cmp word [xa1],30
		je change_sens
		jmp deplace

	change_sens: ;changement de sens du déplacement
		mov ax,[ya1]
		add ax,6
		mov [ya1],ax
		neg word [xinc]

	deplace: ;déplacement des aliens
		mov ax,[xa1]
		add ax,[xinc]
		mov [xa1],ax

	perdu_gagne: ;teste si perdu ou gagné
		cmp word [ya1],120
		jge fin_perdu
		cmp word [nb_aliens],0
		je nouveau_tour

	reinit_vitesse: ;remise à vitesse initiale de vitesse jeu
		mov ax,[vitesse_initiale]
		mov [vitesse],ax

	appuie_touche: ;test de l'appuie de touches
		xor ax,ax
		mov ah,1		;test touche
        int 16h
		jne test_touche
		jmp boucle
		test_touche:
			xor ax,ax
			int 16h
			cmp ax,4B00h
			je gauche
			cmp ax,4D00h
			je droite
			cmp ax,3920h
			je tir
			cmp ax,011bh
			je fin
			cmp ax,4800h
			je fin_perdu
		jmp boucle

tir: ;touche tir
	cmp word [tir_OK],0
	je tir_valide
	jmp boucle
	tir_valide:
		mov ax,[xv]
		add ax,6
		mov [xt],ax
		call affiche_tir
		inc word [tir_OK]
	jmp boucle

gauche: ;touche gauche
	dec dword [xv]
	jmp boucle

droite: ;touche droite
	inc dword [xv]
	jmp boucle

nouveau_tour: ;nouveau tour de jeu (tous les aliens ont été tués)
	call reinit_tour
	call init_tab
	jmp boucle

fin_perdu: ;perdu
	mov word [x],148
	mov word [y],100
	mov word [add_sprite],perdu
	mov word [l],24
	mov word [h],5
	call affiche_sprite
	xor ax,ax
	int 16h

fin: ;quitte le jeu
	mov ax,3h
	int 10h
	retf

reinit_tour: ;reinit pour le tour de jeu suivant (tous les aliens ont été tués)
	mov word [xa1],50
	mov word [ya1],40
	mov word [nb_aliens],55
	mov word [xinc],1
	mov ax,[reduc_vitesse]
	sub word [vitesse_initiale],ax
	cmp word [vitesse_initiale],0
	jne vitesse_pas_0
	mov word [vitesse_initiale],3000
	ret
	vitesse_pas_0:
		mov ax,[vitesse_initiale]
		mov [vitesse],ax
	ret

affiche_tir: ;affichage du tir
	mov dx,[xt]
	mov word [x],dx
	mov dx,[yt]
	mov word [y],dx
	mov word [add_sprite],tir_v
	mov word [l],3
	mov word [h],5
	call affiche_sprite
	dec word [yt]
	mov word [vitesse_tir],0
ret

test_explosion: ;routine de test explosion
	mov ax,[yt]
	mov ax,40
	je stop_tir
	jmp test_boom
	stop_tir:
		mov ax,[yt]
		mov [y],ax
		mov ax,[xt]
		mov [x],ax
		mov word [h],5
		mov word [l],3
		mov word [add_sprite],tir_vide
		call affiche_sprite
		jmp reinit_tir
	test_boom:
	mov cx,320
	mul cx
	mov dx,[xt]
	inc dx
	add dx,ax
	mov di,dx
	mov al,[es:di]
	cmp al,15
	je affiche_boom
	ret
	affiche_boom:
		mov word [qx],0
		mov word [qy],0
		mov ax,[xt]
		sub ax,[xa1]
		inc ax
		xor dx,dx
		div word [la1]
		mov [qx],al
		mov ah,0
		mov ax,[yt]
		sub ax,[ya1]
		xor dx,dx
		div word [ha1]
		mov [qy],al
		mov ax,[qy]
		mul word [tab_alien_l]
		add ax,[qx]
		mov bx,tab_alien
		add bx,ax
		mov byte [bx],7
		push bx
		push ax
		call affichage_aliens
		pop ax
		pop bx
		mov byte [bx],0
		mov bx,tab_alien
		mov bx,ax
		mov byte [bx],0
		dec word [nb_aliens]
	efface_tir:
		mov ax,[yt]
		mov [y],ax
		mov ax,[xt]
		mov [x],ax
		mov word [h],5
		mov word [l],3
		mov word [add_sprite],tir_vide
		call affiche_sprite
		add word [score],10
		call affichage_score
	reinit_tir:
			mov word [tir_OK],0
			mov word [yt],185
ret

affichage_aliens: ;routine d'affichage des aliens
	;pop bx
	mov cx,[tab_alien_h]
	push word [ya1]
	mov ax,[xa1]
	;cmp bx,1
	je sprite_tab_alien
	jmp sprite_tab_alienb
	sprite_tab_alien:
		;add bx,1
		;push bx
		mov bx,tab_alien
		jmp tab_alien_affiche_l
	sprite_tab_alienb:
		;sub bx,1
		;push bx
		mov bx,tab_alienb

	tab_alien_affiche_l:
		push cx
		mov cx,[tab_alien_l]
		push dword [xa1]
		tab_alien_affiche:
			push cx
			mov ax,[ya1]
			mov [y],ax
			mov ax,[xa1]
			mov [x],ax
			mov word [h],12
			mov word [l],16
			;mov ax,alienb
			mov ax,mort
			mov ax,boom
			call test_sprite
			mov [add_sprite],ax
			push bx
			call affiche_sprite
			pop bx
			inc bx
			mov ax,[xa1]
			add ax,16
			mov [xa1],ax
			pop cx
		loop tab_alien_affiche
		pop dword [xa1]
		mov ax,[ya1]
		add ax,12
		mov [ya1],ax
		pop cx
	loop tab_alien_affiche_l
	pop word [ya1]
ret

test_sprite:
	cmp byte [bx],7
	je sprite_boom
	cmp byte [bx],6
	je sprite_alien3b
	cmp byte [bx],5
	je sprite_alien2b
	cmp byte [bx],4
	je sprite_alien1b
	cmp byte [bx],3
	je sprite_alien3
	cmp byte [bx],2
	je sprite_alien2
	cmp byte [bx],1
	je sprite_alien1
	cmp byte [bx],0
	je sprite_alien_mort
		sprite_alien_mort:
			mov ax,mort
			ret
		sprite_alien3:
			mov ax,alien3
			ret
		sprite_alien2:
			mov ax,alien2
			ret
		sprite_alien1:
			mov ax,alien1
			ret
		sprite_alien3b:
			mov ax,alien3b
			ret
		sprite_alien2b:
			mov ax,alien2b
			ret
		sprite_alien1b:
			mov ax,alien1b
			ret
		sprite_boom:
			mov ax,boom
ret

affichage_score: ;routine d'affichage du score
	xor dx,dx
	mov cx,[yc]
	mov ax,[xc]
	push ax
	mov word [h],5
	mov word [l],5
	mov ax,[score]
	mov cx,10
	test_div:
		div cx
		call test_chiffre
		push ax
		push cx
		mov ax,[xc]
		mov [x],ax
		mov [add_sprite],bx
		call affiche_sprite
		sub word [xc],6
		pop cx
		pop ax
		cmp ax,0
		je test_div_fin
		xor dx,dx
		jmp test_div
	test_div_fin:
	pop ax
	mov word [xc],ax
ret

test_chiffre: ;routine de test des chiffres du score
    cmp dx,0
	je chiffre_0
	cmp dx,1
	je chiffre_1
	cmp dx,2
	je chiffre_2
	cmp dx,3
	je chiffre_3
	cmp dx,4
	je chiffre_4
	cmp dx,5
	je chiffre_5
	cmp dx,6
	je chiffre_6
	cmp dx,7
	je chiffre_7
	cmp dx,8
	je chiffre_8
	cmp dx,9
	je chiffre_9
	chiffre_0:
		mov bx,zero
		ret
	chiffre_1:
		mov bx,un
		ret
	chiffre_2:
		mov bx,deux
		ret
	chiffre_3:
		mov bx,trois
		ret
	chiffre_4:
		mov bx,quatre
		ret
	chiffre_5:
		mov bx,cinq
		ret
	chiffre_6:
		mov bx,six
		ret
	chiffre_7:
		mov bx,sept
		ret
	chiffre_8:
		mov bx,huit
		ret
	chiffre_9:
		mov bx,neuf
		ret

affiche_sprite: ;routine d'affichage d'un sprite
	;push cx
	;push dx
	mov bx,[add_sprite]
	mov ax,[y]
	mov cx,320
	mul cx
	mov dx,[x]
	add dx,ax
	mov di,dx
	mov cx,[h]
	ligne:
	push cx
	mov cx,[l]
		col:
			mov al,[bx]
			stosb ;equivalent à mov [es:di],al
			inc bx
		loop col
		sub di,[l]
		add di,320
	pop cx
	loop ligne
	;pop dx
	;pop cx
ret

init_tab: ;remplissage des tableaux des aliens
	mov cx,66
	mov bx,tab_alien
	mov [add1],bx
	mov bx,tab_alien_cte
	mov [add2],bx
	mov bx,tab_alienb
	mov [add3],bx
	mov bx,tab_alienb_cte
	mov [add4],bx
	init_loop:
	    mov bx,[add2]
		mov al,[bx]
		mov bx,[add1]
		mov [bx],al
		mov bx,[add4]
		mov al,[bx]
		mov bx,[add3]
		mov [bx],al
		inc word [add1]
		inc word [add2]
		inc word [add3]
		inc word [add4]
		loop init_loop
ret

[SEGMENT .data]

score dw 0 ;score du jeu
reduc_vitesse dw 500 ;reducteur du compteur de vitesse : permet d'acceler le jeu à chaque nouveau tour
vitesse_initiale dw 30000 ;vitesse du jeu
vitesse dw 30000 ;compteur de vitesse du jeu
vitesse_tir dw 0 ;compteur de vitesse du tir
xinc dw 1 ;1 ou -1 utilisé pour le déplacement des aliens
x dw 0 ;parametre x de la routine d'affichage de sprite
y dw 0 ;parametre y de la routine d'affichage de sprite
h dw 0 ;hauteur du sprite à afficher dans la routine d'affichage
l dw 0 ;largeur du sprite à afficher dans la routine d'affichage
qx dw 0 ;quotient en x pour déterminer l'abscisse de l'alien tué
qy dw 0 ;quotient en y pour déterminer l'abscisse de l'alien tué
xa1 dw 50 ;position initiale x des aliens
ya1 dw 40 ;position initiale y des aliens
la1 dw 16 ;largeur d'un alien
ha1 dw 12 ;hauteur d'un alien
xt dw 0 ;position initiale x du tir
yt dw 185 ;position initiale y du tir
xv dw 160 ;position initiale x du vaisseau
yv dw 190 ;position initiale y du vaisseau
xc dw 70 ;position initiale x d'un chiffre du score
yc dw 10 ;position initiale y d'un chiffre du score
add_sprite dw 0 ;adresse d'un sprite à afficher
tab_alien_l dw 11 ;largeur des tabeaux des aliens
tab_alien_h dw 6 ;hauteur des tableaux des aliens
nb_aliens dw 55 ;nombre d'aliens
tir_OK dw 0 ;variable de test si le tir est OK
add1 dw 0 ;adresse de tab_alien
add2 dw 0 ;adresse de tab_alien_cte
add3 dw 0 ;adresse de tab_alienb
add4 dw 0 ;adresse de tab_alienb_cte

;tableau des aliens allure1 variable (en fonction des aliens tués)
tab_alien db 0,0,0,0,0,0,0,0,0,0,0
		  db 0,0,0,0,0,0,0,0,0,0,0
		  db 0,0,0,0,0,0,0,0,0,0,0
		  db 0,0,0,0,0,0,0,0,0,0,0
		  db 0,0,0,0,0,0,0,0,0,0,0
		  db 0,0,0,0,0,0,0,0,0,0,0

;tableau des aliens allure2 variable (en fonction des aliens tués)
tab_alienb db 0,0,0,0,0,0,0,0,0,0,0
		   db 0,0,0,0,0,0,0,0,0,0,0
		   db 0,0,0,0,0,0,0,0,0,0,0
		   db 0,0,0,0,0,0,0,0,0,0,0
		   db 0,0,0,0,0,0,0,0,0,0,0
		   db 0,0,0,0,0,0,0,0,0,0,0

;tableau des aliens allure1 constant permettant la remise à zéro au tour suivant
tab_alien_cte db 0,0,0,0,0,0,0,0,0,0,0
		      db 5,5,5,5,5,5,5,5,5,5,5
		      db 1,1,1,1,1,1,1,1,1,1,1
		      db 1,1,1,1,1,1,1,1,1,1,1
		      db 3,3,3,3,3,3,3,3,3,3,3
		      db 3,3,3,3,3,3,3,3,3,3,3

;tableau des aliens allure2 constant permettant la remise à zéro au tour suivant
tab_alienb_cte db 0,0,0,0,0,0,0,0,0,0,0
 		       db 2,2,2,2,2,2,2,2,2,2,2
		       db 4,4,4,4,4,4,4,4,4,4,4
		       db 4,4,4,4,4,4,4,4,4,4,4
		       db 6,6,6,6,6,6,6,6,6,6,6
		       db 6,6,6,6,6,6,6,6,6,6,6

;sprite tir vaisseau
tir_v db 00,15,00
	  db 00,15,00
	  db 00,15,00
	  db 00,15,00
	  db 00,00,00

;sprite masque tir vaisseau
tir_vide db 00,00,00
	     db 00,00,00
	     db 00,00,00
	     db 00,00,00
	     db 00,00,00

;sprite alien mort
mort db 00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00
     db 00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00
	 db 00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00
     db 00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00
	 db 00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00
     db 00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00
	 db 00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00
     db 00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00
	 db 00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00
	 db 00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00
	 db 00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00
     db 00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00

;sprite boom
boom db 00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00
     db 00,00,00,15,00,00,00,15,00,00,00,00,00,00,00,00
	 db 00,00,00,00,15,00,00,15,00,00,15,00,00,00,00,00
     db 00,00,00,00,00,15,00,00,00,00,15,00,00,15,00,00
	 db 00,00,00,00,00,00,00,00,00,15,00,00,15,00,00,00
     db 00,00,15,15,00,00,00,00,00,00,00,00,00,00,00,00
	 db 00,00,00,00,00,00,00,00,00,00,00,00,15,15,00,00
     db 00,00,00,15,00,00,15,00,00,00,15,00,00,00,00,00
	 db 00,00,15,00,00,15,00,00,00,00,00,15,00,00,00,00
	 db 00,00,00,00,00,15,00,00,15,00,00,00,15,00,00,00
	 db 00,00,00,00,00,00,00,00,15,00,00,00,00,00,00,00
     db 00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00

;sprite alien1 alure 1
alien1 db 00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00
       db 00,00,00,00,00,15,00,00,00,00,00,15,00,00,00,00
	   db 00,00,00,00,00,00,15,00,00,00,15,00,00,00,00,00
       db 00,00,00,00,00,15,15,15,15,15,15,15,00,00,00,00
	   db 00,00,00,00,15,15,00,15,15,15,00,15,15,00,00,00
       db 00,00,00,15,15,15,15,15,15,15,15,15,15,15,00,00
	   db 00,00,00,15,15,15,15,15,15,15,15,15,15,15,00,00
       db 00,00,00,15,00,15,00,00,00,00,00,15,00,15,00,00
	   db 00,00,00,00,00,00,15,15,00,15,15,00,00,00,00,00
	   db 00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00
	   db 00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00
       db 00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00

;sprite alien1 alure 2
alien1b db 00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00
        db 00,00,00,00,00,15,00,00,00,00,00,15,00,00,00,00
	    db 00,00,00,15,00,00,15,00,00,00,15,00,00,15,00,00
        db 00,00,00,15,00,15,15,15,15,15,15,15,00,15,00,00
	    db 00,00,00,15,15,15,00,15,15,15,00,15,15,15,00,00
        db 00,00,00,15,15,15,15,15,15,15,15,15,15,15,00,00
	    db 00,00,00,00,15,15,15,15,15,15,15,15,15,00,00,00
        db 00,00,00,00,00,15,00,00,00,00,00,15,00,00,00,00
	    db 00,00,00,00,15,00,00,00,00,00,00,00,15,00,00,00
	    db 00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00
   	    db 00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00
        db 00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00

;sprite alien2 alure 1
alien2 db 00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00
       db 00,00,00,00,00,00,00,15,15,00,00,00,00,00,00,00
	   db 00,00,00,00,00,00,15,15,15,15,00,00,00,00,00,00
       db 00,00,00,00,00,15,15,15,15,15,15,00,00,00,00,00
	   db 00,00,00,00,15,15,00,15,15,00,15,15,00,00,00,00
	   db 00,00,00,00,15,15,15,15,15,15,15,15,00,00,00,00
       db 00,00,00,00,00,00,15,00,00,15,00,00,00,00,00,00
       db 00,00,00,00,00,15,00,15,15,00,15,00,00,00,00,00
	   db 00,00,00,00,15,00,15,00,00,15,00,15,00,00,00,00
       db 00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00
	   db 00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00
       db 00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00

;sprite alien2 alure 2
alien2b db 00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00
        db 00,00,00,00,00,00,00,15,15,00,00,00,00,00,00,00
	    db 00,00,00,00,00,00,15,15,15,15,00,00,00,00,00,00
        db 00,00,00,00,00,15,15,15,15,15,15,00,00,00,00,00
	    db 00,00,00,00,15,15,00,15,15,00,15,15,00,00,00,00
	    db 00,00,00,00,15,15,15,15,15,15,15,15,00,00,00,00
        db 00,00,00,00,00,15,00,15,15,00,15,00,00,00,00,00
        db 00,00,00,00,15,00,00,00,00,00,00,15,00,00,00,00
	    db 00,00,00,00,00,15,00,00,00,00,15,00,00,00,00,00
        db 00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00
 	    db 00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00
        db 00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00

;sprite alien3 alure 1
alien3 db 00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00
       db 00,00,00,00,00,00,15,15,15,15,00,00,00,00,00,00
	   db 00,00,00,15,15,15,15,15,15,15,15,15,15,00,00,00
       db 00,00,15,15,15,15,15,15,15,15,15,15,15,15,00,00
	   db 00,00,15,15,15,00,00,15,15,00,00,15,15,15,00,00
	   db 00,00,15,15,15,15,15,15,15,15,15,15,15,15,00,00
	   db 00,00,00,00,15,15,15,00,00,15,15,15,00,00,00,00
       db 00,00,00,15,15,00,00,15,15,00,00,15,15,00,00,00
	   db 00,00,00,00,15,15,00,00,00,00,15,15,00,00,00,00
       db 00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00
	   db 00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00
       db 00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00

;sprite alien3 alure 2
alien3b db 00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00
        db 00,00,00,00,00,00,15,15,15,15,00,00,00,00,00,00
	    db 00,00,00,15,15,15,15,15,15,15,15,15,15,00,00,00
        db 00,00,15,15,15,15,15,15,15,15,15,15,15,15,00,00
	    db 00,00,15,15,15,00,00,15,15,00,00,15,15,15,00,00
	    db 00,00,15,15,15,15,15,15,15,15,15,15,15,15,00,00
	    db 00,00,00,00,00,15,15,00,00,15,15,00,00,00,00,00
        db 00,00,00,00,15,15,00,15,15,00,15,15,00,00,00,00
	    db 00,00,15,15,00,00,00,00,00,00,00,00,15,15,00,00
        db 00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00
	    db 00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00
        db 00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00

;sprite vaisseau
vaisseau db 00,00,00,00,00,00,00,02,00,00,00,00,00,00,00
		 db 00,00,00,00,00,00,02,02,02,00,00,00,00,00,00
		 db 00,00,00,00,00,00,02,02,02,00,00,00,00,00,00
		 db 00,00,02,02,02,02,02,02,02,02,02,02,02,00,00
		 db 00,02,02,02,02,02,02,02,02,02,02,02,02,02,00
		 db 00,02,02,02,02,02,02,02,02,02,02,02,02,02,00
		 db 00,02,02,02,02,02,02,02,02,02,02,02,02,02,00

;sprites des chiffres du score

zero db 00,02,02,02,00
	 db 02,00,00,00,02
	 db 02,00,00,00,02
	 db 02,00,00,00,02
	 db 00,02,02,02,00

un db 00,00,00,02,02
   db 00,00,00,00,02
   db 00,00,00,00,02
   db 00,00,00,00,02
   db 00,00,00,00,02

deux db 02,02,02,02,00
	 db 00,00,00,00,02
	 db 00,02,02,02,02
	 db 02,00,00,00,00
	 db 02,02,02,02,02

trois db 02,02,02,02,00
	  db 00,00,00,00,02
	  db 00,02,02,02,02
	  db 00,00,00,00,02
	  db 02,02,02,02,00

quatre db 02,00,00,00,02
	   db 02,00,00,00,02
	   db 02,02,02,02,02
	   db 00,00,00,00,02
	   db 00,00,00,00,02

cinq db 02,02,02,02,02
	 db 02,00,00,00,00
	 db 02,02,02,02,00
	 db 00,00,00,00,02
	 db 02,02,02,02,00

six  db 00,02,02,02,00
	 db 02,00,00,00,00
	 db 02,02,02,02,00
	 db 02,00,00,00,02
	 db 00,02,02,02,00

sept db 02,02,02,02,02
	 db 00,00,00,00,02
	 db 00,00,00,00,02
	 db 00,00,00,02,00
	 db 00,00,00,02,00

huit db 00,02,02,02,00
	 db 02,00,00,00,02
	 db 00,02,02,02,00
	 db 02,00,00,00,02
	 db 00,02,02,02,00

neuf db 00,02,02,02,00
	 db 02,00,00,00,02
	 db 00,02,02,02,02
	 db 00,00,00,00,02
	 db 00,02,02,02,00

;sprite texte score
textscore db 00,15,15,15,15,00,00,15,15,15,15,00,00,15,15,15,00,00,15,15,15,15,00,00,15,15,15,15,15
		  db 15,00,00,00,00,00,15,00,00,00,00,00,15,00,00,00,15,00,15,00,00,00,15,00,15,00,00,00,00
	      db 00,15,15,15,00,00,15,00,00,00,00,00,15,00,00,00,15,00,15,15,15,15,00,00,15,15,15,15,00
	      db 00,00,00,00,15,00,15,00,00,00,00,00,15,00,00,00,15,00,15,00,00,00,15,00,15,00,00,00,00
	      db 15,15,15,15,00,00,00,15,15,15,15,00,00,15,15,15,00,00,15,00,00,00,15,00,15,15,15,15,15

;sprite message perdu
perdu db 15,15,15,15,00,15,15,15,15,00,15,15,15,15,00,15,15,15,00,00,15,00,00,15
	  db 15,00,00,15,00,15,00,00,00,00,15,00,00,15,00,15,00,00,15,00,15,00,00,15
	  db 15,15,15,15,00,15,15,15,00,00,15,15,15,15,00,15,00,00,15,00,15,00,00,15
	  db 15,00,00,00,00,15,00,00,00,00,15,00,15,00,00,15,00,00,15,00,15,00,00,15
	  db 15,00,00,00,00,15,15,15,15,00,15,00,00,15,00,15,15,15,00,00,15,15,15,15

times  4094 -($-$$) db 0
db	55h,0aah