import tensorflow as tf
from tensorflow.keras import layers, utils, models
import matplotlib.pyplot as plt
import read_image
import numpy as np
from sklearn.preprocessing import OneHotEncoder
from sklearn.preprocessing import LabelEncoder


# Get mammography dataset
train_images = read_image.getFormatDataset()

# Get mammography dataset labels
labels = open("labels", 'r')
train_labels = []
for label in labels:
    label = label.strip()
    label = label.split(' ')
    try:
        if label[3] == 'B':
            train_labels.append('B')
        elif label[3] == 'M':
            train_labels.append('M')
    except Exception as err:
        if label[2] == 'NORM':
            train_labels.append('N')

test_images = []
test_labels = []
j = 0
for j in range(10):
    test_images.append(train_images[j])
    test_labels.append(train_labels[j])

# Format dataset images
train_images = np.array(train_images)
train_images = train_images.reshape(322, 32, 32, 1)

# Format dataset labels
label_encoder = LabelEncoder()
values = np.array(train_labels)
integer_encoded = label_encoder.fit_transform(values)
onehot_encoder = OneHotEncoder(sparse=False)
integer_encoded = integer_encoded.reshape(len(integer_encoded), 1)
onehot_encoded = onehot_encoder.fit_transform(integer_encoded)

# Labels
# N - NORM
# B - Benign
# M - Malign
class_names = ['N', 'B', 'M']

# Creating train model for Convolutional Neural Networks (CNNs)
model = models.Sequential()
model.add(layers.Conv2D(10, (3, 3), activation='relu', input_shape=(32, 32, 1)))
model.add(layers.MaxPooling2D((2, 2)))
model.add(layers.Conv2D(64, (3, 3), activation='relu'))
model.add(layers.MaxPooling2D((2, 2)))
model.add(layers.Conv2D(64, (3, 3), activation='relu'))
model.add(layers.Flatten())
model.add(layers.Dense(64, activation='relu'))
model.add(layers.Dense(3))

# Show the model
model.summary()

# Compile model
model.compile(loss='categorical_crossentropy',optimizer='adam',metrics=['accuracy'])
history = model.fit(train_images, onehot_encoded, epochs=10)

# Format test dataset images
test_images = np.array(test_images)
test_images = test_images.reshape(10, 32, 32, 1)

# Format test dataset labels
label_encoder = LabelEncoder()
values = np.array(test_labels)
integer_encoded = label_encoder.fit_transform(values)
onehot_encoder = OneHotEncoder(sparse=False)
integer_encoded = integer_encoded.reshape(len(integer_encoded), 1)
test_labels = onehot_encoder.fit_transform(integer_encoded)

# Evaluate the CNN model
test_loss, test_acc = model.evaluate(test_images,  test_labels, batch_size=322, verbose=1)

# Show accuracy
print(test_acc)