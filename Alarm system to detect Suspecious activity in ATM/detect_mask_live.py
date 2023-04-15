"""

DETECTING LIVE MASK VIDEO FROM LIVESTREAM

# **Table of Contents**

1. Importing Libraries
2. Defining Face Mask Detection Function
3. Detecting Face Mask from Live Stream

"""

# 1. Importing Libraries

from keras.applications.mobilenet_v2 import preprocess_input
from tensorflow.keras.utils import img_to_array
from keras.models import load_model
from imutils.video import VideoStream
import numpy as np
import argparse
import imutils
import time
import cv2
import os
from pygame import mixer
from os.path import dirname, join

mixer.init()
sound = mixer.Sound('mixkit-security-facility-breach-alarm-994.wav')

# 2. Defining Face Mask Detection Function

def mask_detection_prediction(frame, faceNet, maskNet):
    (h, w) = frame.shape[:2]
    blob = cv2.dnn.blobFromImage(frame, 1.0, (224, 224),(104.0, 177.0, 123.0))
    faceNet.setInput(blob)
    detections = faceNet.forward()
    faces = []
    locs = []
    preds = []
    # Checking for face(s) for the current snapshot of the input image
    for i in range(0, detections.shape[2]):
        confidence = detections[0, 0, i, 2]
        if confidence > 0.5:
            box = detections[0, 0, i, 3:7] * np.array([w, h, w, h])
            (startX, startY, endX, endY) = box.astype("int")
            (startX, startY) = (max(0, startX), max(0, startY))
            (endX, endY) = (min(w - 1, endX), min(h - 1, endY))
            face = frame[startY:endY, startX:endX]
            face = cv2.cvtColor(face, cv2.COLOR_BGR2RGB)
            face = cv2.resize(face, (224, 224))
            face = img_to_array(face)
            face = preprocess_input(face)
            faces.append(face)
            locs.append((startX, startY, endX, endY))
    if len(faces) > 0:
        faces = np.array(faces, dtype="float32")
        preds = maskNet.predict(faces, batch_size=32)
    return (locs, preds)

# deploy.prototxt is a file that specifies the architecture of a neural network in the Caffe deep learning framework. It contains a description of the layers, their types, parameters, and connections between them.
prototxtPath = join("face_detector", "deploy.prototxt")
weightsPath = join("face_detector", "res10_300x300_ssd_iter_140000.caffemodel")

# Loading the trained model
faceNet = cv2.dnn.readNet(prototxtPath, weightsPath)
maskNet = load_model("fmd_model.h5")

# Detecting Face Mask from Live Stream
print("[INFO] starting video stream...")
vs = VideoStream(src=0).start()
while True:
    frame = vs.read()
    frame = imutils.resize(frame, width=400)
    # Using our function to detect masks from livestream
    (locs, preds) = mask_detection_prediction(frame, faceNet, maskNet)
    for (box, pred) in zip(locs, preds):
        (startX, startY, endX, endY) = box
        (mask, withoutMask) = pred
        if mask>withoutMask:
            label = "Mask"
            color = (0, 255, 0)
            sound.play()
            print("Alert")
        else:
            label = "No Mask"
            color = (0, 0, 255)
            print("Normal")
        label = "{}: {:.2f}%".format(label, max(mask, withoutMask) * 100)
        cv2.putText(frame, label, (startX, startY - 10),cv2.FONT_HERSHEY_SIMPLEX, 0.45, color, 2)
        cv2.rectangle(frame, (startX, startY), (endX, endY), color, 2)
    cv2.imshow("Frame", frame)
    key = cv2.waitKey(1) & 0xFF
    if key == ord("q"):
        break
cv2.destroyAllWindows()
vs.stop()

