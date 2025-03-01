from ultralytics import YOLO
import os
import random
import cv2



# Modified here to switch model
model = YOLO('yolo11n.pt')
# model = YOLO('yolov8n.pt')

'''
- Images won't be uploaded to Git.
- COCO dataset: (https://cocodataset.org/#download)
- You can change the path below to the local path of your own dataset (images).

- Supported formats are:
    - images: {'tiff', 'mpo', 'webp', 'dng', 'bmp', 'pfm', 'jpg', 'tif', 'jpeg', 'heic', 'png'}
'''

coco_val_path = "Data/val2017"
list_of_images = os.listdir(coco_val_path)
selected_image = random.choice(list_of_images)
selected_image_path = os.path.join(coco_val_path, selected_image)

'''
If you don't understand the codes below,
DO NOT modify any of them
'''

results = model(selected_image_path)
test_image=cv2.imread(selected_image_path)
font_size = max(1,int(test_image.shape[1] / 800))

for result in results:
    for box in result.boxes:
        x1, y1, x2, y2 = box.xyxy[0] # coordinate of object in the image. Top left:(x1,y1); Bottom right:(x2,y2)
        detected_object = result.names[int(box.cls[0])] # object name
        conf = box.conf[0] # confidence

        print(f"Object:{detected_object}, Confidence:{conf:.4f}")
        print(f"Coordinate of object:({x1:.2f}),({y1:.2f}),({x2:.2f}),({y2:.2f})\n")

        cv2.rectangle(test_image, (int(x1), int(y1)), (int(x2), int(y2)), (0, 255, 0), 2)
        cv2.putText(test_image, f"{detected_object}({conf:.4f})",(int(x1),int(y2)-10),cv2.FONT_HERSHEY_PLAIN,font_size,(0,255,0),2)

cv2.imshow('Object detection', test_image)
cv2.waitKey(0)


# mAP, Precise, Recall
# val = model.val(data='Data/coco.yaml')
# for key,value in val.items():
#     print(f"{key}:{value}")

