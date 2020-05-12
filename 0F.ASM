
; fasm 16-bit COM program

	org     100h                    ; code starts at offset 100h
	use16                           ; use 16-bit code

display_text    = 9
create_file     = 3ch
write_file      = 40h
close_file      = 3eh
delete_file     = 41h
get_attributes  = 4300h

	cld
	mov     bp,cline        ;bp=cmdline
	mov     di,bp
	xor     ax,ax
	mov     cx,128+16384    ;cmdline+wbuf
	rep     stosw           ;clear write buffer
	mov     cl,[80h]        ;cmdline length
	jcxz    short nocp
	mov     di,bp
	mov     si,81h
	rep     movsb
nocp:   mov     si,bp
	mov     bp,cx           
	inc     bp              ;bp=1 auto-delete by default
	mov     di,fname        ;di=00000000.000
	lodsb
	test    al,al
	jz      short emptcl
	mov     dx,hlp
	cmp     al,'/'
	jne     short chk2nd
sh:     jmp     msgdxq
chk2nd: lodsb
	cmp     al,'/'
	je      short sh
	cmp     al,'-'
	je      short sh
	cmp     al,'?'
	je      short sh
	cmp     al,'+'
	jne     short noad
	dec     bp                      ;bp=0 - don't auto-delete
	lodsb
noad:   test    al,al
	jz      short emptcl
	cmp     al,'A'                  ; a:...z:
	jb      short sh
	cmp     al,'z'
	ja      short sh
	cmp     al,'a'
	jae     driveL
	cmp     al,'Z'
	ja      short sh
driveL: mov     [dname],al
	sub     di,fname-dname
emptcl: mov     ax,get_attributes
	mov     dx,di
	int     21h
	jc      short no0f
	cmp     di,fname
	mov     si,di
	mov     cl,erree - fname - 1    ;no trailing 0
	mov     di,dname
	je      nodrv                   ;only file name, move
	add     cx,fname - dname        ;don't move, shift di
nodrv:  rep     movsb
	mov     si,erree
	mov     cl,strmb - erree
	rep     movsb
	mov     dx,errex
	jmp     msgdxq
no0f:   mov     ah,create_file
	mov     dx,di
	xor     cx,cx
	int     21h
	jnc     short opens
	mov     dx,errcf
	jmp     msgdxq
opens:  test    bp,bp
	jz      noadn
	mov     bp,di
noadn:  xchg    bx,ax           ;bx=handle
	mov     cx,32768
	mov     dx,wbuf
	xor     si,si
	mov     di,si           ;si:di=size
wrtfl:  mov     ah,write_file
	int     21h
	jc      short erwfm
	cmp     ax,cx
	jnb     havees
	shr     cx,1
	jnz     wrtfl
	mov     dx,eol          ;finish
	jmp     clsmsq
havees: add     di,ax
	adc     si,0
	or      di,di
	jnz     wrtfl
	test    si,01111b
	jnz     wrtfl           ;not 1Mb boundary
	push    dx
	push    cx
	
	mov     cl,4
	mov     ax,si
	xor     dx,dx
	shr     ax,cl
	mov     cx,10
	div     cx
	or      dl,30h
	mov     [strmb+3],dl
	or      ax,ax
	jz      short shown
	xor     dx,dx
	div     cx
	or      dl,30h
	mov     [strmb+2],dl
	aam
	or      ah,ah
	jz      nol0
	or      ah,30h
	mov     [strmb],ah
	jmp     haves0
nol0:   or      al,al
	jz      shown
haves0: or      al,30h
	mov     [strmb+1],al
shown:  mov     dx,strmb
	mov     ah,display_text
	int     21h

	pop     cx
	pop     dx
	jmp     wrtfl

erwfm:  mov     dx,errwf
clsmsq: mov     ah,close_file   ;bx=handle, dx=msg     
	int     21h
	test    bp,bp
	jz      msgdxq          ;don't delete 00000000.000
	push    dx
	mov     dx,bp
	mov     ah,delete_file
	int     21h
	pop     dx
msgdxq: mov     ah,display_text
	int     21h

	int     20h

errcf db 'Can not create cleaning file.',24h
errwf db 'Can not write to file.',24h
errex db 'File '
dname db 'A:\'
fname db '00000000.000',0
erree db ' already exists. STOP!',24h
strmb db '   0 ',24h
eol   db 0dh,0ah,'Finished.',24h
hlp   db 'Fills free space with zeroes in file "00000000.000".',0dh,0ah
      db 'Usage: 0f.com [-][/][?] | [+][L]',0dh,0ah
      db '? - this help',0dh,0ah
      db 'L - clear space on drive L:',0dh,0ah
      db '+ - keep file 00000000.000',24h
cline db 256 dup(?)
wbuf  db 32768 dup(?)
