import os

import numpy as np
import torch
import torch.nn.functional as F
import torch.onnx
from torch import nn
from torch import optim

import torch.utils.data as data

import brevitas.nn as qnn
from brevitas.core.quant import QuantType
import brevitas.onnx as bo

from random import shuffle
from torch.utils.tensorboard import SummaryWriter

# --------------------------
#  Neural Network Definition
# --------------------------
class QuantLeNet(nn.Module):
    def __init__(self):
        super(QuantLeNet, self).__init__()
        self.conv1 = qnn.QuantConv2d(1, 6, 5, 
                                     weight_quant_type=QuantType.INT, 
                                     weight_bit_width=8 , padding=2)
        self.relu1 = qnn.QuantReLU(quant_type=QuantType.INT, bit_width=8, max_val=6)
        self.conv2 = qnn.QuantConv2d(6, 16, 5, 
                                     weight_quant_type=QuantType.INT, 
                                     weight_bit_width=8)
        self.relu2 = qnn.QuantReLU(quant_type=QuantType.INT, bit_width=8, max_val=6)
        self.fc1   = qnn.QuantLinear(16*5*5, 120, bias=True, 
                                     weight_quant_type=QuantType.INT, 
                                     weight_bit_width=8)
        self.relu3 = qnn.QuantReLU(quant_type=QuantType.INT, bit_width=8, max_val=6)
        self.fc2   = qnn.QuantLinear(120, 84, bias=True, 
                                     weight_quant_type=QuantType.INT, 
                                     weight_bit_width=8)
        self.relu4 = qnn.QuantReLU(quant_type=QuantType.INT, bit_width=8, max_val=6)
        self.fc3   = qnn.QuantLinear(84, 10, bias=False, 
                                     weight_quant_type=QuantType.INT, 
                                     weight_bit_width=8)

    def forward(self, x):
        out = self.relu1(self.conv1(x))
        out = F.max_pool2d(out, 2)
        out = self.relu2(self.conv2(out))
        out = F.max_pool2d(out, 2)
        out = torch.flatten(out, 1)
        out = self.relu3(self.fc1(out))
        out = self.relu4(self.fc2(out))
        out = self.fc3(out)
        return out


net = QuantLeNet()
print(net)

use_gpu = torch.cuda.is_available()
if use_gpu:
    net = net.cuda()
    print('USE GPU')
else:
    print('USE CPU')


optimizer = optim.Adam(net.parameters(), lr=0.001, betas=(0.9,0.999), weight_decay=1e-5)
scheduler = optim.lr_scheduler.StepLR(optimizer, step_size=5000, gamma=0.5)
criterion = nn.CrossEntropyLoss()

# --------------------------
#  1. Loading Official MNIST Dataset
# --------------------------
print("Loading data")

def load_mnist_from_raw(path='./datasets/MNIST/raw', train=True):
    import gzip

    if train:
        images_file = os.path.join(path, 'train-images-idx3-ubyte.gz')
        labels_file = os.path.join(path, 'train-labels-idx1-ubyte.gz')
    else:
        images_file = os.path.join(path, 't10k-images-idx3-ubyte.gz')
        labels_file = os.path.join(path, 't10k-labels-idx1-ubyte.gz')

    # Load images
    with gzip.open(images_file, 'rb') as f:
        data = np.frombuffer(f.read(), np.uint8, offset=16)
        data = data.reshape(-1, 1, 28, 28).astype(np.float32) / 255.0

    # Load labels
    with gzip.open(labels_file, 'rb') as f:
        labels = np.frombuffer(f.read(), np.uint8, offset=8).astype(np.int64)

    return torch.from_numpy(data), torch.from_numpy(labels)

# Load training and test data
X_data, X_label = load_mnist_from_raw(train=True)
Y_tensor, Y_label_tensor = load_mnist_from_raw(train=False)

print(f"Training data: {X_data.size()}, Labels: {X_label.size()}")
print(f"Test data: {Y_tensor.size()}, Labels: {Y_label_tensor.size()}")

# --------------------------
#  3. Training phase
# --------------------------
nb_epoch = 50
nb_batch = 128

train_dataset = data.TensorDataset(X_data, X_label)
train_loader = data.DataLoader(
    dataset=train_dataset,
    batch_size=nb_batch,
    shuffle=True,
    drop_last=False
)

writer = SummaryWriter('runs/lenet5_experiment')
global_step = 0  
best_loss = float('inf')

for epoch in range(5):
    net.train()
    epoch_loss = 0.0
    correct = 0
    total = 0

    for batch_idx, (mini_data, mini_label) in enumerate(train_loader):

        if use_gpu:
            mini_data = mini_data.cuda()
            mini_label = mini_label.cuda()

        optimizer.zero_grad()
        mini_out = net(mini_data)
        mini_loss = criterion(mini_out, mini_label)
        mini_loss.backward()
        torch.nn.utils.clip_grad_norm_(net.parameters(), max_norm=1.0)
        optimizer.step()
    
        _, predicted = torch.max(mini_out.data, 1)
        total += mini_label.size(0)
        correct += (predicted == mini_label).sum().item()
    
        epoch_loss += mini_loss.item()
    
        if (batch_idx + 1) % 100 == 0:
            print(f'Epoch [{epoch+1}/{nb_epoch}], Step [{batch_idx+1}/{len(train_loader)}], '
                  f'Loss: {mini_loss.item():.4f}, LR: {optimizer.param_groups[0]["lr"]:.6f}')

        writer.add_scalar('Loss/Batch', mini_loss.item(), global_step)
        writer.add_scalar('Learning_rate', optimizer.param_groups[0]['lr'], global_step)
        global_step += 1

    avg_loss = epoch_loss / len(train_loader)
    accuracy = 100.0 * correct / total
    
    writer.add_scalar('Loss/Train', avg_loss, epoch)
    writer.add_scalar('Accuracy/Train', accuracy, epoch)
    
    for name, param in net.named_parameters():
        if 'weight' in name:
            writer.add_histogram(f'Weight/{name}', param, epoch)
        if 'bias' in name:
            writer.add_histogram(f'Bias/{name}', param, epoch)
            
    scheduler.step()
    
    if avg_loss < best_loss:
        best_loss = avg_loss
        torch.save({
            'epoch': epoch + 1,
            'model_state_dict': net.state_dict(),
            'optimizer_state_dict': optimizer.state_dict(),
            'loss': best_loss,
            'accuracy': accuracy
        }, 'best_lenet5_model.pth')
        
    print(f"Saved Best Model, Epoch {epoch+1}, Loss: {avg_loss:.4f}, Accuracy: {accuracy:.2f}%")

# --------------------------
#  4. Testing phase
# --------------------------
test_dataset = data.TensorDataset(Y_tensor, Y_label_tensor)
test_loader = data.DataLoader(
    dataset=test_dataset,
    batch_size=128,
    shuffle=False,
    drop_last=False
)

net.eval()
test_loss = 0.0
correct = 0
total = 0

with torch.no_grad():
    for mini_data, mini_label in test_loader:
        if use_gpu:
            mini_data = mini_data.cuda()
            mini_label = mini_label.cuda()

        outputs = net(mini_data)
        loss = criterion(outputs, mini_label)
        test_loss += loss.item()

        _, predicted = torch.max(outputs.data, 1)
        total += mini_label.size(0)
        correct += (predicted == mini_label).sum().item()

avg_test_loss = test_loss / len(test_loader)
test_accuracy = 100.0 * correct / total

print("=" * 50)
print(f"Test Loss: {avg_test_loss:.4f}")
print(f"Test Accuracy: {test_accuracy:.2f}%")
print("=" * 50)

writer.add_scalar('Loss/Test', avg_test_loss, epoch)
writer.add_scalar('Accuracy/Test', test_accuracy, epoch)
writer.close()

# --------------------------
#  5. Convert to ONNX
# --------------------------
print('Converting to ONNX')
net.eval()
batch_size = 1
if use_gpu:
    x = torch.randn(batch_size, 1, 28, 28, requires_grad=True).cuda()
else:
    x = torch.randn(batch_size, 1, 28, 28, requires_grad=True)

torch_out = net(x)

model_path = "models"
os.makedirs(model_path, exist_ok=True)

bo.export_qonnx(
    net,
    x,
    os.path.join(model_path, "exported_raw.onnx"),
    export_params=True,
    opset_version=9,
    do_constant_folding=False,
    input_names=['input'],
    output_names=['output'],
    dynamic_axes=None
)

