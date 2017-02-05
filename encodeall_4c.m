close all

x = dir('wav\*.wav');
nfiles = size(x,1);
% nfiles = 1;

snr_new = zeros(nfiles,1);
gains = zeros(nfiles,1);

for i=1:nfiles
    disp (x(i).name);
    
    gain = 0.21;
    gstep = 0.01;
    
    snr = 0;
    su = 1;
    sd = 1;
    
    while ~((snr>su) && (snr>sd))

        if (su>sd)
            gain  = gain + gstep;
        end
        
        if (su<sd)
            gain  = gain - gstep;
        end

        su  = scc_int8(gain + gstep,['wav\' x(i).name],i-1);        close all
        sd  = scc_int8(gain - gstep,['wav\' x(i).name],i-1);        close all
        snr = scc_int8(gain        ,['wav\' x(i).name],i-1);        close all

        gain
        snr
        
    end
    
    snr_new(i) = snr;
    gains(i) = gain;
end

gain = 2*mean(gains);
for i=1:nfiles
    disp (x(i).name);
    snr_new(i) = scc_int8(gain,['wav\' x(i).name],i-1);
    close all    
end

% disp (x(1).name);
% return

for i=1:nfiles
    disp (x(i).name);
    disp (snr_new(i))
end
    
fid = fopen('SfxTable.asm','wb');
for i=1:nfiles
	s = num2str(i-1);
    fwrite(fid,['         dw     06000h + (s' s '_START & 01FFFH)' 13 10],'char');
    fwrite(fid,['         db     s' s '_START/02000h-2' 13 10],'char');
    fwrite(fid,['         dw     (s' s '_END - s' s '_START+127)/128' 13 10],'char');
    fwrite(fid,['    ' 13 10],'char');
end
fclose(fid);


fid = fopen('DataTable.asm','wb');
for i=1:nfiles
	s = num2str(i-1);
    fwrite(fid,['s' s '_START:' 13 10],'char');
    fwrite(fid,['         incbin data' s '.bin ' 13 10],'char');
    fwrite(fid,['s' s '_END:' 13 10],'char');
end
fclose(fid);


delete data*.mat ;
movefile('data*.bin','.\bin');

!.\sjasm42c\sjasm -i.\bin SccReplayer4c.asm
