nwavs:       equ  9

         dw     04000h + (s0_START & 01FFFH)
         db     s0_START/02000h-2
         dw     (s0_END - s0_START+95)/96
    
         dw     04000h + (s1_START & 01FFFH)
         db     s1_START/02000h-2
         dw     (s1_END - s1_START+95)/96
    
         dw     04000h + (s2_START & 01FFFH)
         db     s2_START/02000h-2
         dw     (s2_END - s2_START+95)/96
    
         dw     04000h + (s3_START & 01FFFH)
         db     s3_START/02000h-2
         dw     (s3_END - s3_START+95)/96
    
         dw     04000h + (s4_START & 01FFFH)
         db     s4_START/02000h-2
         dw     (s4_END - s4_START+95)/96
    
         dw     04000h + (s5_START & 01FFFH)
         db     s5_START/02000h-2
         dw     (s5_END - s5_START+95)/96
    
         dw     04000h + (s6_START & 01FFFH)
         db     s6_START/02000h-2
         dw     (s6_END - s6_START+95)/96
    
         dw     04000h + (s7_START & 01FFFH)
         db     s7_START/02000h-2
         dw     (s7_END - s7_START+95)/96
    
         dw     04000h + (s8_START & 01FFFH)
         db     s8_START/02000h-2
         dw     (s8_END - s8_START+95)/96
    
