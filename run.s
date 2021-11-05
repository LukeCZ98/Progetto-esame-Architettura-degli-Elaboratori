.section .rodata
filename: .asciz "running.dat"
read_mode: .asciz "r"
write_mode: .asciz "w"

fmt_menu_title:
    
    .ascii "   
            █▀█ █░█ █▄░█ █▄░█ █ █▄░█ █▀▀   █▀▀ █░█ █▀▀ █▀▀ █▄▀
            █▀▄ █▄█ █░▀█ █░▀█ █ █░▀█ █▄█   █▄▄ █▀█ ██▄ █▄▄ █░█    \n"

fmt_menu_line:
    .asciz "-------------------------------------------------------------------------------------------------------\n"
fmt_menu_header:
    .asciz "  # GIORNO               VELOCITA'(km/h)                 Km                 Kcal                 Bpm\n"
fmt_menu_entry:
    .asciz "%3d %-10s           %-20d     %9d %20d         %11d\n"
fmt_menu_options:
    .ascii "1: Aggiungi giorno\n"
    .ascii "2: Elimina giorno\n"
    .ascii "3: Calcola media Kcal bruciate (int)\n" 
    .ascii "4: Calcola velocita' media (float)\n" 
    .ascii "5: Calcola media Km percorsi (float)\n"
    .ascii "6: Calcola media Bpm (int)\n"
    .ascii "7: Giorno max Km percorsi\n"
    .asciz "0: Esci\n"
fmt_velocita_media: .asciz "\nVelocita' media: %.2f\n\n"
fmt_kcal_media: .asciz "\nMedia calorie bruciate: %d\n\n"
fmt_media_km: .asciz "\nMedia km percorsi: %.2f\n\n"
fmt_media_bpm: .asciz "\nMedia bpm: %d\n\n"
fmt_giorno_max: .asciz "\nGiorno max Km percorsi: %s\n\n"
fmt_fail_save_data: .asciz "\nImpossibile salvare i dati.\n\n"
fmt_fail_aggiungi_giorno: .asciz "\nMemoria insufficiente. Eliminare un giorno, quindi riprovare.\n\n"
fmt_fail_calcola_bpm_medi: .asciz "\nNessun giorno registrato.\n\n"
fmt_fail_calcola_velocita_media: .asciz "\nNessun giorno registrato.\n\n"
fmt_fail_calcola_media_km: .asciz "\nNessun giorno registrato.\n\n"
fmt_fail_calcola_giorno_max: .asciz "\nNessun giorno registrato.\n\n"
fmt_scan_int: .asciz "%d"
fmt_scan_str: .asciz "%127s"
fmt_error_elimina: .asciz "\nNessun giorno da eliminare!\n\n"
fmt_prompt_menu: .asciz "Scegli: "
fmt_prompt_giorno: .asciz "Giorno (stringa): "
fmt_prompt_velocita: .asciz "Velocita' (int): "
fmt_prompt_km: .asciz "Km percorsi (int): "
fmt_prompt_kcal: .asciz "Kcal spese (int): "
fmt_prompt_bpm: .asciz "Bpm (int): "
fmt_prompt_index: .asciz "# (fuori range per annullare): "
.align 2

.data
n_giorni: .word 0

.equ max_giorni, 5
.equ size_giorno_giorno, 20
.equ size_giorno_velocita, 4  
.equ size_giorno_km, 4      
.equ size_giorno_kcal, 4   
.equ size_giorno_bpm, 4    

.equ offset_giorno_giorno, 0
.equ offset_giorno_velocita, offset_giorno_giorno + size_giorno_giorno
.equ offset_giorno_km, offset_giorno_velocita + size_giorno_velocita
.equ offset_giorno_kcal, offset_giorno_km + size_giorno_km
.equ offset_giorno_bpm, offset_giorno_kcal + size_giorno_kcal
.equ giorni_size_aligned, 40

.bss
tmp_str: .skip 128
tmp_int: .skip 8
tmp_flt: .skip 8
giorni: .skip giorni_size_aligned * max_giorni


.macro read_int prompt
    adr x0, \prompt
    bl printf

    adr x0, fmt_scan_int
    adr x1, tmp_int
    bl scanf

    ldr x0, tmp_int
.endm

.macro read_str prompt
    adr x0, \prompt
    bl printf

    adr x0, fmt_scan_str
    adr x1, tmp_str
    bl scanf
.endm

.macro save_to item, offset, size
    add x0, \item, \offset
    ldr x1, =tmp_str
    mov x2, \size
    bl strncpy

    add x0, \item, \offset + \size - 1
    strb wzr, [x0]
.endm


.text
.type main, %function
.global main
main:
    stp x29, x30, [sp, #-16]!

    bl load_data

    main_loop:
        bl print_menu
        read_int fmt_prompt_menu
        
        cmp x0, #0
        beq end_main_loop
        
        cmp x0, #1
        bne no_aggiungi_giorno
        bl aggiungi_giorno
        no_aggiungi_giorno:

        cmp x0, #2
        bne no_elimina_giorno
        bl elimina_giorno
        no_elimina_giorno:

        cmp x0, #3
        bne no_calcola_kcal_media
        bl calcola_kcal_media
        no_calcola_kcal_media:

        cmp x0, #4
        bne no_calcola_velocita_media
        bl calcola_velocita_media
        no_calcola_velocita_media:
        
        cmp x0, #5
        bne no_calcola_media_km
        bl calcola_media_km
        no_calcola_media_km:

        cmp x0, #6
        bne no_calcola_bpm_medi
        bl calcola_bpm_medi
        no_calcola_bpm_medi:
        
        cmp x0, #7
        bne no_calcola_giorno_max
        bl calcola_giorno_max
        no_calcola_giorno_max:

        b main_loop     
    end_main_loop:

    mov w0, #0
    ldp x29, x30, [sp], #16
    ret
    .size main, (. - main)


.type load_data, %function
load_data:
    stp x29, x30, [sp, #-16]!
    str x19, [sp, #-8]!
    
    adr x0, filename
    adr x1, read_mode
    bl fopen

    cmp x0, #0
    beq end_load_data

    mov x19, x0

    ldr x0, =n_giorni
    mov x1, #5
    mov x2, #1
    mov x3, x19
    bl fread

    ldr x0, =giorni
    mov x1, giorni_size_aligned
    mov x2, max_giorni
    mov x3, x19
    bl fread

    mov x0, x19
    bl fclose

    end_load_data:

    ldr x19, [sp], #8
    ldp x29, x30, [sp], #16
    ret
    .size load_data, (. - load_data)


.type save_data, %function
save_data:
    stp x29, x30, [sp, #-16]!
    str x19, [sp, #-8]!
    
    adr x0, filename
    adr x1, write_mode
    bl fopen

    cmp x0, #0
    beq fail_save_data

        mov x19, x0

        ldr x0, =n_giorni
        mov x1, #5
        mov x2, #1
        mov x3, x19
        bl fwrite

        ldr x0, =giorni
        mov x1, giorni_size_aligned
        mov x2, max_giorni
        mov x3, x19
        bl fwrite

        mov x0, x19
        bl fclose

        b end_save_data

    fail_save_data:
        adr x0, fmt_fail_save_data
        bl printf

    end_save_data:

    ldr x19, [sp], #8
    ldp x29, x30, [sp], #16
    ret
    .size save_data, (. - save_data)


.type print_menu, %function
print_menu:
    stp x29, x30, [sp, #-16]!
    stp x19, x20, [sp, #-16]!
    stp x21, x22, [sp, #-16]!

    adr x0, fmt_menu_title
    bl printf

    adr x0, fmt_menu_line
    bl printf
    adr x0, fmt_menu_header
    bl printf
    adr x0, fmt_menu_line
    bl printf

    mov x19, #0
    ldr x20, n_giorni
    ldr x21, =giorni
    print_entries_loop:
        cmp x19, x20
        bge end_print_entries_loop

        adr x0, fmt_menu_entry
        add x1, x19, #1
        add x2, x21, offset_giorno_giorno         //stringa
        ldr x3, [x21, offset_giorno_velocita]    //int 
        ldr x4, [x21, offset_giorno_km]          //int
        ldr x5, [x21, offset_giorno_kcal]        //int
        ldr x6, [x21, offset_giorno_bpm]         //int
        bl printf

        add x19, x19, #1
        add x21, x21, giorni_size_aligned
        b print_entries_loop
    end_print_entries_loop:

    adr x0, fmt_menu_line
    bl printf

    adr x0, fmt_menu_options
    bl printf

    ldp x21, x22, [sp], #16
    ldp x19, x20, [sp], #16
    ldp x29, x30, [sp], #16
    ret
    .size print_menu, (. - print_menu)


.type aggiungi_giorno, %function
aggiungi_giorno:
    stp x29, x30, [sp, #-16]!
    stp x19, x20, [sp, #-16]!
    
    ldr x19, n_giorni
    ldr x20, =giorni
    mov x0, giorni_size_aligned
    mul x0, x19, x0
    add x20, x20, x0
    
    cmp x19, max_giorni
    bge fail_aggiungi_giorno
    
        read_str fmt_prompt_giorno
        save_to x20, offset_giorno_giorno, size_giorno_giorno
        
        read_int fmt_prompt_velocita
        str w0, [x20, offset_giorno_velocita]
        
        read_int fmt_prompt_km
        str w0, [x20, offset_giorno_km]
        
        read_int fmt_prompt_kcal
        str w0, [x20, offset_giorno_kcal]      

        read_int fmt_prompt_bpm
        str w0, [x20, offset_giorno_bpm]
        

        add x19, x19, #1
        ldr x20, =n_giorni
        str x19, [x20]

        bl save_data

        b end_aggiungi_giorno 
    fail_aggiungi_giorno:
        adr x0, fmt_fail_aggiungi_giorno
        bl printf
    end_aggiungi_giorno:
    
    ldp x19, x20, [sp], #16
    ldp x29, x30, [sp], #16
    ret
    .size aggiungi_giorno, (. - aggiungi_giorno)


.type elimina_giorno, %function
elimina_giorno:
    stp x29, x30, [sp, #-16]!
    
    read_int fmt_prompt_index

    cmp x0, 1
    blt end_elimina_giorno

    ldr x1, n_giorni
    cmp x0, x1
    bgt end_error

    sub x5, x0, 1   // selected index
    ldr x6, n_giorni
    sub x6, x6, x0  // number of auto after selected index
    mov x7, giorni_size_aligned
    ldr x0, =giorni
    mul x1, x5, x7  // offset to dest
    add x0, x0, x1  // dest
    add x1, x0, x7  // source
    mul x2, x6, x7  // bytes to copy
    bl memcpy

    ldr x0, =n_giorni
    ldr x1, [x0]
    sub x1, x1, #1
    str x1, [x0]

    bl save_data
    b end_elimina_giorno

    end_error:
    adr x0, fmt_error_elimina
    bl printf

    end_elimina_giorno:
    
    ldp x29, x30, [sp], #16
    ret
    .size elimina_giorno, (. - elimina_giorno)


.type calcola_kcal_media, %function
calcola_kcal_media:
    stp x29, x30, [sp, #-16]!
    
    ldr w0, n_giorni
    cmp w0, #0
    beq calcola_kcal_media_error

        mov w1, #0
        mov w2, #0
        ldr x3, =giorni
        add x3, x3, offset_giorno_kcal
        calcola_kcal_media_loop:
            ldr w4, [x3]
            add w1, w1, w4
            add x3, x3, giorni_size_aligned

            add w2, w2, #1
            cmp w2, w0
            blt calcola_kcal_media_loop
        
        udiv w1, w1, w0
        adr x0, fmt_kcal_media
        bl printf

        b end_calcola_kcal_media

    calcola_kcal_media_error:
        adr x0, fmt_fail_calcola_velocita_media
        bl printf
    
    end_calcola_kcal_media:

    ldp x29, x30, [sp], #16
    ret
    .size calcola_kcal_media, (. - calcola_kcal_media)


.type calcola_velocita_media, %function
calcola_velocita_media:
    stp x29, x30, [sp, #-16]!
    
    ldr w0, n_giorni
    cmp w0, #0
    beq calcola_velocita_media_error

        fmov d1, xzr
        mov w2, #0
        ldr x3, =giorni
        add x3, x3, offset_giorno_velocita
        calcola_velocita_media_loop:
            ldr w4, [x3]
            ucvtf d4, x4
            fadd d1, d1, d4
            add x3, x3, giorni_size_aligned

            add w2, w2, #1
            cmp w2, w0
            blt calcola_velocita_media_loop
        
        ucvtf d0, w0
        fdiv d0, d1, d0
        adr x0, fmt_velocita_media
        bl printf

        b end_calcola_velocita_media

    calcola_velocita_media_error:
        adr x0, fmt_fail_calcola_velocita_media
        bl printf
    
    end_calcola_velocita_media:

    ldp x29, x30, [sp], #16
    ret
    .size calcola_velocita_media, (. - calcola_velocita_media)

.type calcola_bpm_medi, %function
calcola_bpm_medi:
    stp x29, x30, [sp, #-16]!
    
    ldr w0, n_giorni
    cmp w0, #0
    beq calcola_bpm_medi_error

        mov w1, #0
        mov w2, #0
        ldr x3, =giorni
        add x3, x3, offset_giorno_bpm
        calcola_bpm_medi_loop:
            ldr w4, [x3]
            add w1, w1, w4
            add x3, x3, giorni_size_aligned

            add w2, w2, #1
            cmp w2, w0
            blt calcola_bpm_medi_loop
        
        udiv w1, w1, w0
        adr x0, fmt_media_bpm
        bl printf

        b end_calcola_bpm_medi

    calcola_bpm_medi_error:
        adr x0, fmt_fail_calcola_bpm_medi
        bl printf
    
    end_calcola_bpm_medi:

    ldp x29, x30, [sp], #16
    ret
    .size calcola_bpm_medi, (. - calcola_bpm_medi)

.type calcola_media_km, %function
calcola_media_km:
    stp x29, x30, [sp, #-16]!
    
    ldr w0, n_giorni
    cmp w0, #0
    beq calcola_media_km_error

        fmov d1, xzr
        mov w2, #0
        ldr x3, =giorni
        add x3, x3, offset_giorno_km
        calcola_media_km_loop:
            ldr w4, [x3]
            ucvtf d4, x4
            fadd d1, d1, d4
            add x3, x3, giorni_size_aligned

            add w2, w2, #1
            cmp w2, w0
            blt calcola_media_km_loop
        
        ucvtf d0, w0
        fdiv d0, d1, d0
        adr x0, fmt_media_km
        bl printf

        b end_calcola_media_km

    calcola_media_km_error:
        adr x0, fmt_fail_calcola_media_km
        bl printf
    
    end_calcola_media_km:

    ldp x29, x30, [sp], #16
    ret
    .size calcola_media_km, (. - calcola_media_km)

.type calcola_giorno_max, %function
calcola_giorno_max:
    stp x29, x30, [sp, #-16]!
    
    ldr w0, n_giorni
    cmp w0, #0
    beq calcola_giorno_max_error

        mov w1, #0
        mov w2, #0
        mov w17, #0                            //giorno di riferimento
        mov w18, #0                            //valore max di riferimento
        ldr x3, =giorni
        add x4, x3, offset_giorno_km           //uso l'offset dei dati da calcolare          //x4=offset km
        add x5, x3, offset_giorno_giorno                                                     //x5=offset giorni
        calcola_giorno_max_loop:
            ldr w6, [x4]                         //metto in x6 il valore dei km tramite l'offset settato in x4
            mov w7, w5                         //in x7 carico il giorno corrispondente a quei km
            
            cmp w6, w18                          //lunedi
            blt else                             //14km
            mov w18, w6
            mov w17, w7
             
            else:
            add x4, x4, giorni_size_aligned      //aumento come una sorta di counter per passare al valore successivo 
            add x5, x5, giorni_size_aligned      //usiamo la size allineante per spostarci grazie anche agli offset per ottenere i vari valori
            
            add w2, w2, #1                      
            cmp w2, w0
            blt calcola_giorno_max_loop         //transformare la funzione utilizzando il debugging per facilitare
                                                //leggendo i valori nei registri
        mov w1, w17
        adr x0, fmt_giorno_max
        bl printf

        b end_calcola_giorno_max

    calcola_giorno_max_error:
        adr x0, fmt_fail_calcola_giorno_max
        bl printf
    
    end_calcola_giorno_max:

    ldp x29, x30, [sp], #16
    ret
    .size calcola_giorno_max, (. - calcola_giorno_max)
    
