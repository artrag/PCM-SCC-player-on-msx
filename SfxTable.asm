nwavs:       equ  12

         dw     06000h + (s0_START & 01FFFH)
         db     s0_START/02000h-2
         dw     (s0_END - s0_START+95)/96
    
         dw     06000h + (s1_START & 01FFFH)
         db     s1_START/02000h-2
         dw     (s1_END - s1_START+95)/96
    
         dw     06000h + (s2_START & 01FFFH)
         db     s2_START/02000h-2
         dw     (s2_END - s2_START+95)/96
    
         dw     06000h + (s3_START & 01FFFH)
         db     s3_START/02000h-2
         dw     (s3_END - s3_START+95)/96
    
         dw     06000h + (s4_START & 01FFFH)
         db     s4_START/02000h-2
         dw     (s4_END - s4_START+95)/96
    
         dw     06000h + (s5_START & 01FFFH)
         db     s5_START/02000h-2
         dw     (s5_END - s5_START+95)/96
    
         dw     06000h + (s6_START & 01FFFH)
         db     s6_START/02000h-2
         dw     (s6_END - s6_START+95)/96
    
         dw     06000h + (s7_START & 01FFFH)
         db     s7_START/02000h-2
         dw     (s7_END - s7_START+95)/96
    
         dw     06000h + (s8_START & 01FFFH)
         db     s8_START/02000h-2
         dw     (s8_END - s8_START+95)/96
    
         dw     06000h + (s9_START & 01FFFH)
         db     s9_START/02000h-2
         dw     (s9_END - s9_START+95)/96
    
         dw     06000h + (s10_START & 01FFFH)
         db     s10_START/02000h-2
         dw     (s10_END - s10_START+95)/96
    
         dw     06000h + (s11_START & 01FFFH)
         db     s11_START/02000h-2
         dw     (s11_END - s11_START+95)/96
    
