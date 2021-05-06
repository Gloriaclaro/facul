import re
import numpy
import cv2
from matplotlib import pyplot


def read_pgm(filename, byteorder='>'):
    """Return image data from a raw PGM file as numpy array.

    Format specification: http://netpbm.sourceforge.net/doc/pgm.html

    """
    with open(filename, 'rb') as f:
        buffer = f.read()
    try:
        header, width, height, maxval = re.search(
            b"(^P5\s(?:\s*#.*[\r\n])*"
            b"(\d+)\s(?:\s*#.*[\r\n])*"
            b"(\d+)\s(?:\s*#.*[\r\n])*"
            b"(\d+)\s(?:\s*#.*[\r\n]\s)*)", buffer).groups()
        # print("w", width.decode(encoding = 'utf-8'))
        # print("h", height.decode(encoding='utf-8'))
    except AttributeError:
        raise ValueError("Not a raw PGM file: '%s'" % filename)
    return numpy.frombuffer(buffer,
                            dtype='u1' if int(maxval) < 256 else byteorder+'u2',
                            count=int(width)*int(height),
                            offset=len(header)
                            ).reshape((int(height), int(width))), height, width


def getFormatDataset():
    combination = ['ls', 'lm', 'll', 'lx', 'rs', 'rm', 'rl', 'rx']
    j = 0
    mammography_dataset = []
    i = 0
    for i in range(323):
        for el in combination:
            try:
                if int(i) < 10 and el == 'ls':
                    i = "00"+str(i)
                elif int(i) < 100 and el == 'ls':
                    i = "0"+str(i)
                image, height, width = read_pgm(f"mdb{i}{el}.pgm", byteorder='<')
                # Get shortest width and height
                if j == 0:
                    shortest_height = height.decode(encoding='utf-8')
                    shortest_width = width.decode(encoding='utf-8')
                    j = j + 1
                aux_w = width.decode(encoding='utf-8')
                aux_h = height.decode(encoding='utf-8')
                if aux_w < shortest_width:
                    shortest_width = aux_w
                if aux_h < shortest_height:
                    shortest_height = aux_h
                # print(height, width)
                # Resize image with shortest size in the dataset
                res = cv2.resize(image, dsize=(32, 32), interpolation=cv2.INTER_CUBIC)
                # pyplot.imshow(image, pyplot.cm.gray)
                # pyplot.show()
                # pyplot.imshow(res, pyplot.cm.gray)
                # pyplot.show()
                # Save treated images in the dataset
                mammography_dataset.append(res)
            except FileNotFoundError as err:
                continue
    return mammography_dataset
    # print(shortest_height, shortest_width)


if __name__ == "__main__":
    getFormatDataset()