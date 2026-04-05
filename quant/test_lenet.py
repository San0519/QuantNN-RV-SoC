import os

import onnx

from source.onnx_interface.model_scoring import scoreMnist

model_path = "models/"
model_path = os.path.join(model_path, "exported_raw.onnx")


def check_model():
    print('check ONNX model')
    onnx_model = onnx.load(model_path)
    onnx.checker.check_model(onnx_model)


def score_model():
    print('test ONNX model')

    print(scoreMnist(model_path))


if __name__ == "__main__":
    check_model()
    score_model()
