import cv2
import numpy as np
from matplotlib import pyplot

img = cv2.imread('mdp001lm.pgm')
res = cv2.resize(img, dsize=(4320, 1600), interpolation=cv2.INTER_CUBIC)
pyplot.imshow(img, pyplot.cm.gray)
pyplot.show()
pyplot.imshow(img, pyplot.cm.gray)
pyplot.show()