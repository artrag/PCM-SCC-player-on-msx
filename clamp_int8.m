function [out,err] = clamp_int8(in)
out = double(int8(max(min(in ,127),-128)));
err = -(in - out);
err = max(min(err ,127),-128)/3.5;
end
