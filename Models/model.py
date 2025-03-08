from ultralytics import YOLO
import os
import random
import cv2



# model = YOLO('yolo11n.pt')
model = YOLO('yolov8n.pt')
model.export(imgsz=320,format='tflite')


#=============IMAGE=============#

'''
- Supported formats are:
    - images: {'tiff', 'mpo', 'webp', 'dng', 'bmp', 'pfm', 'jpg', 'tif', 'jpeg', 'heic', 'png'}
'''

# image_path = "Data/val2017"
# list_of_images = os.listdir(image_path)
# selected_image = random.choice(list_of_images)
# selected_image_path = os.path.join(image_path, selected_image)
#
# results = model(selected_image_path)
# test_image=cv2.imread(selected_image_path)
# font_size = max(1,int(test_image.shape[1] / 800))
#
# for result in results:
#     for box in result.boxes:
#         x1, y1, x2, y2 = box.xyxy[0] # coordinate of object in the image. Top left:(x1,y1); Bottom right:(x2,y2)
#         detected_object = result.names[int(box.cls[0])] # object name
#         conf = box.conf[0] # confidence
#
#         print(f"Object:{detected_object}, Confidence:{conf:.4f}")
#         print(f"Coordinate of object:({x1:.2f}),({y1:.2f}),({x2:.2f}),({y2:.2f})\n")
#
#         cv2.rectangle(test_image, (int(x1), int(y1)), (int(x2), int(y2)), (0, 255, 0), 2)
#         cv2.putText(test_image, f"{detected_object}({conf:.4f})",(int(x1),int(y2)-10),cv2.FONT_HERSHEY_PLAIN,font_size,(0,255,0),2)
#
# cv2.imshow('Object detection', test_image)
# cv2.waitKey(0)


#=============VIDEO=============#
# video_path = "Data/video"
# list_of_video = os.listdir(video_path)
# selected_video = random.choice(list_of_video)
# selected_video_path = os.path.join(video_path, selected_video)
# cap = cv2.VideoCapture(selected_video_path)
#
# while True:
#     ret, frame = cap.read()
#
#     # for video recorded by iOS only
#     frame = cv2.flip(frame, 0)
#
#     results=model(frame)
#     font_size = max(1, int(frame.shape[1] / 800))
#
#     for result in results:
#         for box in result.boxes:
#             x1, y1, x2, y2 = box.xyxy[0]
#             detected_object = result.names[int(box.cls[0])]
#             conf = box.conf[0]
#
#             # 绘制矩形框
#             cv2.rectangle(
#                 frame,
#                 (int(x1), int(y1)),
#                 (int(x2), int(y2)),
#                 (0, 255, 0), 2
#             )
#             # 在框上方放置信息
#             cv2.putText(
#                 frame,
#                 f"{detected_object}({conf:.4f})",
#                 (int(x1), int(y2) - 10),
#                 cv2.FONT_HERSHEY_PLAIN,
#                 font_size,
#                 (0, 255, 0),
#                 2
#             )
#
#     cv2.imshow('Object Detection', frame)
#     if cv2.waitKey(1) & 0xFF == 27:  # press esc to break
#         break
#
#
# cap.release()
# cv2.destroyAllWindows()
