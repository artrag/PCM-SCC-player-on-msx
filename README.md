# PCM-SCC-player-on-msx
This player and encoder allows to use the SCC chip to play pcm audio on the ISR 

The player needs cycle accurate code in the ISR so it has to be specialized for NTSC and PAL machines. 
The current repository is strictly tailored for NTSC machines. Use the roms on PAL and you will get very low SNR audio.

The PAL version of the encoder/replayers will released in a separate repository.
Naturally data processed for NTSC, if used on PAL replayers will suffer a 10% slowdown 


The system, on real HW, due to a well known SCC bug on the wave buffer of the 4th channel, uses only 3 channels.

This means that the audio is resampled at 3*32*60 = 5760Hz by the encoder
Very low for anything except basses and maybe human voice.
(things go even worst on PAL sytems, as you get 3*32*50 = 4800Hz)

On SCC+ in SCC mode and on modern SCC chips the bug is absent and one can use 4 channels.
This means  that the audio in the encoder is resampled at 4*32*60 = 7680Hz (6400Hz on PAL)

Naturally data processed on 3 channels and on 4 channels differ, so you cannot reuse them if you want to support both SCC and SCC+

A game supporting SCC and SCC+ (3 and 4 channels) should store twice the data (4 times if you count  NTSC and PAL)

