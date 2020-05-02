# Stress Buster AR

## 1. A little demo
![image](./assets/demo.gif)

## 2. More about this app
* This app integrates Apple's two awesome frameworks CoreML, ARKit together.
* AR session gives CoreML input, and CoreML output tells ARKit where to place the virtual node for foot detected.
* Due to lack of data, the CoreML model might be biased. Works best with bare foot or wearing white socks on wooden floor.

## 3. Important stuff
### `FootSeg.mlmodel`:
* Semantic segmentation model trained on pytorch.
* Converts 224\*224 image to 112\*112 binary mask.
* Use U-Net as backbone.
* Use weights from MobileNet-v2 for transfer learning. 
* Checkout code from [this amazing repo](https://github.com/akirasosa/mobile-semantic-segmentation).

## 4. TODO
* Upload a better version of the COVID-19 3D model. The one that's on the repo may be buggy.

