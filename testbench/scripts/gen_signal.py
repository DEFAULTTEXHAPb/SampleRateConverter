import os
import numpy as np
from numpy import pi
import matplotlib.pyplot as plt
import fxpmath as fp
from fxpmath import Fxp

F = 1000 # frequency in hertz
Fs = 96000 # sample frequency in hertz
N = 5 * Fs / F # Sample count
Ts = 2 * pi * F / Fs
samples = np.linspace(0, N, num=int(N))
sinus = np.sin(Ts*samples)
plt.plot(Ts*samples, sinus)
plt.show()
#os.system("pause")
signal = Fxp(sinus, dtype='fxp-s32/31')
plt.plot(Ts*samples, signal.get_val())
plt.show()
#os.system("pause")
#print(signal)
tv = open(".\\simulation\\test_vector_signal.txt", mode="r+")
#tv = open(".\\test_vector_signal.txt", mode="r+")
tv.truncate(0)

length = len(signal)

i = 0
for sample in signal:    
    #print(sample.bin)
    i += 1
    if(i != (length)):
        string = str(sample.bin()) + "\n"
    else:
        string = str(sample.bin())
    tv.writelines(string)


tv.close()