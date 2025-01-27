/* Example linker script for RV32I core */

/* Define the memory regions */
MEMORY
{
    ROM (rx)  : ORIGIN = 0x00000000, LENGTH = 0x00010000  /* 64KB ROM */
    SRAM (rwx) : ORIGIN = 0x80000000, LENGTH = 0x00008000 /* 32KB SRAM */
}

/* Define the entry point */
ENTRY(_start)

/* Define sections and their placement in memory */
SECTIONS
{
    /* Place the .text section in ROM */
    .text :
    {
        _start = .;       /* Define the start label */
        *(.text);         /* Place all .text sections here */
        *(.text.*);       /* Place all .text.* sections here */
    } > ROM

    /* Place the .rodata section in ROM */
    .rodata :
    {
        *(.rodata);       /* Place all .rodata sections here */
        *(.rodata.*);     /* Place all .rodata.* sections here */
    } > ROM

    /* Place the .data section in SRAM */
    .data :
    {
        _data = .;        /* Define the data start label */
        *(.data);         /* Place all .data sections here */
        *(.data.*);       /* Place all .data.* sections here */
        _edata = .;       /* Define the end of data label */
    } > SRAM AT > ROM

    /* Place the .bss section in SRAM */
    .bss :
    {
        _bss = .;         /* Define the bss start label */
        *(.bss);          /* Place all .bss sections here */
        *(.bss.*);        /* Place all .bss.* sections here */
        _ebss = .;        /* Define the end of bss label */
    } > SRAM

    /* Define the end of the program */
    _end = .;
}