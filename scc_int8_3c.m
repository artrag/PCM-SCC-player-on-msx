function [out] = scc_int8_3c(gain,name,num)

Fr = 60/1.001;
fc = ((455/2) * (525/2) * (60/1.001));

[Y,Fs] = audioread(name);

Nch = 3;

Frs = fix(Nch*32*Fr);
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
audiowrite(['temp_' name(1:(end-4)) '_tst_5.7KHz.wav'],Y,Frs,'BitsPerSample',24);

Y = Y*gain*127;
L = size(Y,1);

Z = zeros(Nch*fix(L/Nch)+Nch,1);
Z(1:L) = Y;
Y = Z;
clear Z;

ph1 = Y(1:Nch:end);
ph2 = Y(2:Nch:end);
ph3 = Y(3:Nch:end);

ch1 = zeros(size(ph1));
ch2 = zeros(size(ph1));
ch3 = zeros(size(ph1));

[ch1(1),err] = clamp_int8(ph1(1) - 0      - 0      + 0);
[ch2(1),err] = clamp_int8(ph2(1) - ch1(1) - 0      + 0);
[ch3(1),err] = clamp_int8(ph3(1) - ch1(1) - ch2(1) + 0);


for i=2:size(Y)/Nch
    [ch1(i),err] = clamp_int8(ph1(i)-ch2(i-1)-ch3(i-1) + err);
    [ch2(i),err] = clamp_int8(ph2(i)-ch1(i)  -ch3(i-1) + err);
    [ch3(i),err] = clamp_int8(ph3(i)-ch1(i)  -ch2(i)   + err);
end


figure
t = 1:size(ch1,1);
plot(t,ch1,'b',t,ch2,'r',t,ch3,'g')

C1 = kron(double(ch1),[1;1;1]);
C2 = kron(double(ch2),[1;1;1]);
C3 = kron(double(ch3),[1;1;1]);

Z = C1 + [0; C2(1:end-1)] + [0;0; C3(1:end-2)];

close all
figure;
subplot(2,1,1); 
plot (1:size(Y,1),Y,'b',1:size(Z,1),Z,'r')
title('Blue: original, Red: replayer')
subplot(2,1,2); 
plot(1:size(Y,1),abs(Z-Y))
title('Error')

disp(' ');

out = convert2db(sqrt(norm(Y)/norm((Z-Y)))); 
disp(['snr (db)= ', num2str(out)]);
disp(['Max err= ', num2str(max(abs(double(Z-Y)/256)))]);

c1 = double(ch1);
c2 = double(ch2);
c3 = double(ch3);

% t = [];
% for i=1:32:(size(c1,1)-32)
%     t = [t; c1(i:(i+31)); c2(i:(i+31)); c3(i:(i+31))];
% end


fname = [ 'data' num2str(num) '.bin'];
fid = fopen(fname,'wb');
for i=1:32:(size(c1,1)-32)
    fwrite(fid,(c1(i:(i+31))),'int8');
    fwrite(fid,(c2(i:(i+31))),'int8');
    fwrite(fid,(c3(i:(i+31))),'int8');
%    fwrite(fid,zeros(32,1),'int8');
end
fclose(fid);

ft = Fr*32;
P = fix(fc/ft-1);

% disp(['Ideal period of the SCC waves (hex) ',dec2hex(P) ]);
% disp(['Offset in cycles among channels ',num2str(fc/(Frs))]);

%fname = [ 'data' num2str(num) '.mat'];
%save(fname);

