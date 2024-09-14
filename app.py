from flask import Flask, request, jsonify
from PIL import Image
import torch
from efficientnet_pytorch import EfficientNet
import torch.nn.functional as F
from torchvision import transforms
import io

app = Flask(__name__)

# 모델 클래스 정의 및 모델 로드
model_name = 'efficientnet-b0'
model = EfficientNet.from_name(model_name)

num_classes = 2
model._fc = torch.nn.Linear(model._fc.in_features, num_classes)

# 모델 가중치 로드 (경로 수정)
model.load_state_dict(torch.load(r'C:\Users\USER\Desktop\model\promotion_model.pt', map_location=torch.device('cpu')))
model.eval()

# 이미지 전처리 함수
preprocess = transforms.Compose([
    transforms.Resize(224),
    transforms.CenterCrop(224),
    transforms.ToTensor(),
    transforms.Normalize(mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225]),
])

@app.route('/predict', methods=['POST'])
def predict():
    if 'file' not in request.files:
        return jsonify({'error': 'No file part'}), 400

    file = request.files['file']

    if file.filename == '':
        return jsonify({'error': 'No selected file'}), 400

    image = Image.open(io.BytesIO(file.read()))
    input_tensor = preprocess(image)
    input_batch = input_tensor.unsqueeze(0)

    if torch.cuda.is_available():
        input_batch = input_batch.to('cuda')
        model.to('cuda')

    with torch.no_grad():
        output = model(input_batch)

    probabilities = F.softmax(output, dim=1)
    _, predicted_class = torch.max(probabilities, 1)

    return jsonify({
        'predicted_class': '사칭 광고' if predicted_class.item() == 0 else '실제 광고',
        'probabilities': probabilities.tolist()
    })

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)
