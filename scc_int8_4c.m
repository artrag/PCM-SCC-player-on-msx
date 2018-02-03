function [out] = scc_int8_4c(in,name,num)

Fr = 60/1.001;
fc = ((455/2) * (525/2) * (60/1.001));

[Y,Fs] = audioread(name);

Frs = fix(4*32*Fr);
G = gcd(Fs,Frs);
P = Frs/G;
Q = Fs/G;

Y = double(Y);

    % convert to mono
if (size(Y,2)>1)
    Y = Y(:,1)+Y(:,2);
end

Y = resample(Y,P,Q);
Y = 2.0*Y/(max(Y)-min(Y));
Y = Y - (max(Y)-1);
audiowrite(['temp_' name(1:(end-4)) '_tst_7.6KHz.wav'],Y,Frs,'BitsPerSample',24);

Y = Y*in*127;
l = size(Y,1);

%l / Frs;

Z = zeros(4*fix(l/4)+4,1);
Z(1:l) = Y;
clear Y
Y = Z;

ph1 = Y(1:4:end);
ph2 = Y(2:4:end);
ph3 = Y(3:4:end);
ph4 = Y(4:4:end);

ch1 = int8(zeros(size(ph1)));
ch2 = int8(zeros(size(ph2)));
ch3 = int8(zeros(size(ph3)));
ch4 = int8(zeros(size(ph4)));

[ch1(1),err] = clamp_int8(ph1(1)                                 );
[ch2(1),err] = clamp_int8(ph2(1) - ch1(1)                   + err);
[ch3(1),err] = clamp_int8(ph3(1) - ch1(1) - ch2(1)          + err);
[ch4(1),err] = clamp_int8(ph4(1) - ch1(1) - ch2(1) - ch3(1) + err);

for i=2:size(Y)/4
    [ch1(i),err] = clamp_int8(ph1(i)-ch2(i-1)-ch3(i-1)-ch4(i-1) + err);
    [ch2(i),err] = clamp_int8(ph2(i)-ch1(i)  -ch3(i-1)-ch4(i-1) + err);
    [ch3(i),err] = clamp_int8(ph3(i)-ch1(i)  -ch2(i)  -ch4(i-1) + err);
    [ch4(i),err] = clamp_int8(ph4(i)-ch1(i)  -ch2(i)  -ch3(i)   + err);
end


figure
t = 1:size(ch1,1);
plot(t,ch1,'b',t,ch2,'r',t,ch3,'g',t,ch4,'c')

C1 = kron(double(ch1),[1;1;1;1]);
C2 = kron(double(ch2),[1;1;1;1]);
C3 = kron(double(ch3),[1;1;1;1]);
C4 = kron(double(ch4),[1;1;1;1]);

Z = C1 + [0; C2(1:end-1)] + [0;0; C3(1:end-2)] + [0;0;0; C4(1:end-3)];

%close all
figure;
title('Blue: original, Red: replayer')
plot (1:size(Y,1),Y,'b',1:size(Z,1),Z,'r')
figure;
title('Error')
plot(1:size(Y,1),(Z-Y))

disp(' ');

out = convert2db(sqrt(norm(Y)/norm((Z-Y)))); 
disp(['snr (db)= ', num2str(out)]);
disp(['Max err= ', num2str(max(abs(double(Z-Y)/256)))]);


c1 = double(ch1);
c2 = double(ch2);
c3 = double(ch3);
c4 = double(ch4);

nfad = 16;
i = size(c1,1)-nfad:size(c1,1);
fad = [1:-1/nfad:0]';

c1(i) = c1(i).*fad;
c2(i) = c2(i).*fad;
c3(i) = c3(i).*fad;
c4(i) = c4(i).*fad;


fname = [ 'data' num2str(num) '.bin'];
fid = fopen(fname,'wb');
for i=1:32:(size(ch1,1)-32)
    fwrite(fid,(c1(i:(i+31))),'int8');
    fwrite(fid,(c2(i:(i+31))),'int8');
    fwrite(fid,(c3(i:(i+31))),'int8');
    fwrite(fid,(c4(i:(i+31))),'int8');    
end
fclose(fid);

ft = Fr*32;
P = fix(fc/ft-1);

%disp(['Ideal period of the SCC waves (hex) ',dec2hex(P) ]);

%disp(['Offset in cycles among channels ',num2str(fc/(Frs))]);

%fname = [ 'data' num2str(num) '.mat'];
%save(fname);

