import torch
import torch.nn as nn
import torch.nn.functional as F

class SensorLSTM(nn.Module):
    def __init__(self, num_classes):
        super(SensorLSTM, self).__init__()
        self.input_proj = nn.Linear(12, 32)
        self.lstm       = nn.LSTM(input_size=32, hidden_size=64, num_layers=2, batch_first=True)
        self.classifier = nn.Linear(64, num_classes)

    def forward(self, x):
        # x: (batch, timesteps, 12)
        x, _ = self.lstm(self.input_proj(x))
        x     = x[:, -1, :]                 # last time step
        return self.classifier(x)           # wrapper applies softmax
