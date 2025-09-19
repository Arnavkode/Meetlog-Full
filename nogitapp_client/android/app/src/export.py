# src/export_mobile_model.py

import torch
from wrapper_model import WrappedModel

def export_mobile():
    # 1) CPU is fine for scripting
    device = torch.device("cpu")
    wrapper = WrappedModel(num_classes=12).to(device)

    # 2) Load weights just like above
    raw_state = torch.load("model_new.pt", map_location=device)
    wrapped_state = {f"core.{k}": v for k, v in raw_state.items()}
    wrapper.load_state_dict(wrapped_state)
    wrapper.eval()

    # 3) Script & save
    ts_mod = torch.jit.script(wrapper)
    ts_mod.save("model_mobile.pt")
    print("Saved mobile model to models/model_mobile.pt")

if __name__ == "__main__":
    export_mobile()
