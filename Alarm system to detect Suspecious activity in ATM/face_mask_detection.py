"""
PROJECT NAME: FACE MASK DETECTION FOR ATM SECURITY 
BY ABHISHEK ANAND, JAY PRAKASH PANDEY AND ROHAN DAS

# **Table of Contents**

1. Introduction
2. Fetch datasets from kaggle
3. Load Dataset
4. Import library
5. Data Augmentation
6. Model Building
7. Model Fitting
8. Training Loss & Accuracy Visualization
9. Find prediction

# **Introduction**
### **Objective**
The objective of this project is to detect the presence of a face mask on human faces on live streaming video as well as on images and alert the authority to take action on those who'r not wearing mask.
### **Dataset**
Click [here](https://www.kaggle.com/prithwirajmitra/covid-face-mask-detection-dataset) to download the dataset.

The use of several datasets was necessary to collect different scenarios:
- People of different racial and ethnicities
- Masks of different types
- Masks in different positions
- Different Angles

# **1. Fetch datasets from kaggle**
"""
# Commenting this because we have to run theese commands separately in the terminal
# !mkdir ~/.kaggle
# !mv /content/sample_data/kaggle.json ~/.kaggle/kaggle.json
# from kaggle.api.kaggle_api_extended import KaggleApi
# api = KaggleApi()
# api.authenticate()
# !chmod 600 ~/.kaggle/kaggle.json
# !kaggle datasets download -d prithwirajmitra/covid-face-mask-detection-dataset

"""# **2. Load Dataset**"""
from zipfile import ZipFile
zf = ZipFile('/content/covid-face-mask-detection-dataset.zip')
zf.extractall('/content/sample_data') #save files in selected folder
zf.close()

"""# **3. Import Libraries**"""

import os
import cv2
import numpy as np
import random
import keras

from imutils import paths
import matplotlib.pyplot as plt
from tensorflow.keras.applications.mobilenet_v2 import preprocess_input
from tensorflow.keras.preprocessing.image import img_to_array
from keras.preprocessing.image import ImageDataGenerator, load_img
from tensorflow.keras.utils import to_categorical
from sklearn.preprocessing import LabelBinarizer

from tensorflow.keras.applications import MobileNetV2
from tensorflow.keras.layers import Input
from tensorflow.keras.layers import AveragePooling2D
from tensorflow.keras.layers import Dropout,BatchNormalization,MaxPooling2D
from tensorflow.keras.layers import Flatten
from tensorflow.keras.layers import Dense
from tensorflow.keras.layers import Input
from tensorflow.keras import Sequential
from tensorflow.keras.models import Model
from tensorflow.keras.optimizers import Adam

from keras.callbacks import ModelCheckpoint
from keras.callbacks import EarlyStopping, ReduceLROnPlateau
from sklearn.metrics import classification_report

"""# **4. Sample Image**
### **With Mask**
"""

images_withMask = os.listdir("/content/sample_data/New Masks Dataset/Train/Mask")
sample_img_withMask = random.choice(images_withMask)
image = load_img("/content/sample_data/New Masks Dataset/Train/Mask/"+sample_img_withMask)
plt.imshow(image)

"""### **Without Mask**"""

images_withoutMask = os.listdir("/content/sample_data/New Masks Dataset/Train/Non Mask")
sample_img_withoutMask = random.choice(images_withoutMask)
image = load_img("/content/sample_data/New Masks Dataset/Train/Non Mask/"+sample_img_withoutMask)
plt.imshow(image)

"""# **5. Data Augmentation**"""
img_width=224
img_height=224
INIT_LR = 1e-4
EPOCHS = 50
BS = 32
train_data_dir="/content/sample_data/New Masks Dataset/Train"
test_data_dir="/content/sample_data/New Masks Dataset/Validation"

all_train_imagePaths = list(paths.list_images(train_data_dir))
all_test_imagePaths = list(paths.list_images(test_data_dir))
train_data = []
train_labels = []
test_data = []
test_labels = []
for imagePath in all_train_imagePaths:
	label = imagePath.split(os.path.sep)[-2]
	image = load_img(imagePath, target_size=(224, 224))
	image = img_to_array(image)
	image = preprocess_input(image)
	train_data.append(image)
	train_labels.append(label)
for imagePath in all_test_imagePaths:
	label = imagePath.split(os.path.sep)[-2]
	image = load_img(imagePath, target_size=(224, 224))

	image = img_to_array(image)
	image = preprocess_input(image)
	test_data.append(image)
	test_labels.append(label)

def convert_data_labels(data,labels):
  data = np.array(data, dtype="float32")
  labels = np.array(labels)
  lb = LabelBinarizer()
  labels = lb.fit_transform(labels)
  labels = to_categorical(labels)
  return  data,labels

train_data,train_labels = convert_data_labels(train_data,train_labels)
test_data,test_labels = convert_data_labels(test_data,test_labels)

print("==================================")
print("Size of train dataset : ",train_data.shape[0])
print("==================================")
print("Size of test dataset : ",test_data.shape[0])
print("==================================")

train_datagen = ImageDataGenerator(
                  rotation_range=20,
                  zoom_range=0.15,
                  width_shift_range=0.2,
                  height_shift_range=0.2,
                  shear_range=0.15,
                  horizontal_flip=True,
                  fill_mode="nearest")

train_generator = train_datagen.flow(train_data, train_labels, batch_size=BS)

"""# **6. Model Building**

### **6.1. Load MobileNetV2**
"""
mobilenet = MobileNetV2(weights="imagenet", include_top=False, input_tensor=Input(shape=(224, 224, 3)))
headModel = mobilenet.output
headModel = AveragePooling2D(pool_size=(7, 7))(headModel)
headModel = Flatten(name="flatten")(headModel)
headModel = Dense(128, activation="relu")(headModel)
headModel = Dropout(0.5)(headModel)
headModel = Dense(2, activation="softmax")(headModel)
model = Model(inputs=mobilenet.input, outputs=headModel)

print("[INFO] compiling model...")
opt = Adam(learning_rate=INIT_LR, decay=INIT_LR / EPOCHS)
model.compile(loss="binary_crossentropy", optimizer=opt,metrics=["accuracy"])
print("Done !!")
for layer in mobilenet.layers:
	layer.trainable = False

from datetime import datetime
def timer(start_time= None):
  if not start_time:
    start_time=datetime.now()
    return start_time
  elif start_time:
    thour,temp_sec=divmod((datetime.now()-start_time).total_seconds(),3600)
    tmin,tsec=divmod(temp_sec,60)
    print('\n Time taken: %i hours %i minutes and %s seconds. '% (thour,tmin,round(tsec,2)))

"""### **6.2. Callback Function**"""

earlystop = EarlyStopping(monitor = 'val_loss',
                          min_delta = 0,
                          patience = 7,
                          verbose = 1,
                          restore_best_weights = True)

checkPoint = keras.callbacks.ModelCheckpoint(filepath="/content/sample_data/fmd_model.h5",
                             monitor='val_loss',
                             mode='auto',
                             save_best_only=True,
                             verbose=1)

learning_rate_reduction = ReduceLROnPlateau(monitor='val_accuracy', 
                                            patience=2, 
                                            verbose=1, 
                                            factor=0.5, 
                                            min_lr=0.00001)


callbacks = [earlystop , checkPoint, learning_rate_reduction]

"""# **7. Model Fitting**"""

start_time=timer(None)
classifier = model.fit(
    train_datagen.flow(train_data, train_labels, batch_size=BS), 
    epochs=EPOCHS,
    validation_data=(test_data,test_labels),
    validation_steps=len(test_data)//BS,
    steps_per_epoch=len(train_data)//BS,
    callbacks=callbacks
)
timer(start_time)

"""# **8. Training Loss and Accuracy Visualization**"""
plt.style.use("ggplot")
N = 10 
plt.figure()
plt.plot( classifier.history["loss"], label="train_loss")
plt.plot( classifier.history["val_loss"], label="val_loss")
plt.plot( classifier.history["accuracy"], label="train_acc")
plt.plot( classifier.history["val_accuracy"], label="val_acc")
plt.title("Training Loss and Accuracy")
plt.xlabel("Epoch #")
plt.ylabel("Loss/Accuracy")
plt.legend(loc="center right")
plt.savefig("CNN_Model")

"""### **8.1. Find Prediction**"""
print("[INFO] evaluating network...")
predIdxs = model.predict(test_data, batch_size=BS)
predIdxs = np.argmax(predIdxs, axis=1)

"""### **8.2. Find Accuracy**"""
val_loss,val_acc = model.evaluate(test_data,test_labels)
print("=======================================================")
print("Accuracy is : ",val_acc)
print("=======================================================")
print("Loss is : ",val_loss)
print("=======================================================")

"""### **8.3. Classification Report**"""
print(classification_report(test_labels.argmax(axis=1), predIdxs))



