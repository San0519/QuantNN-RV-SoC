# QuantNN-RV-SoC 
## Description
QuantNN-RV-SoC is a project that implements a quantized neural network (QNN) on a RISC-V System on Chip (SoC). The project includes the design and implementation of the hardware architecture, as well as the software components necessary for running the QNN on the SoC. The main goal of this project is to demonstrate the feasibility and performance of running quantized neural networks on RISC-V based SoCs, which can be beneficial for edge computing applications where power efficiency and low latency are crucial.

The whole workflow from neural network design, training and quantization to the SoC integration and FPGA prototyping are through and through. Differening from the traditional pure Vitis HLS based implementation, this project utilizes [FINN](https://github.com/Xilinx/finn), a dedicated maching learning frame work developed and maintained by Xilinx. Its frontend works on [Brevitas](https://github.com/Xilinx/brevitas), which is a Pytorch library for neural network quantization that supports both post-training quantization (PTQ) and quantization-aware training (QAT), with various ways from 1-bit to 8-bit weights or activations. It maps the neural network in a highly flexibile and configurable way into hardware (FPGA) resource like LUT, DSP and BRAM by calling a *finn-hlslib*.

## File Tree
```bash
├── docs: documents and diagram
├── finn: FINN build directory
│   └── example: an official example of FPGA dataflow of FINN
│       └── templates
├── quant: neural network quantization by Brevitas
│   ├── datasets
│   │   └── MNIST
│   │       └── raw
│   ├── models
│   ├── onnx_interface
│   └── runs
│       └── lenet5_experiment
├── src: design resources and testbench files
│   └── tb
└── sw: test program and compile files
    ├── database: MNIST verification database and processing files
    │   └── single_test: single input test
    └── program: test program and compile files
        └── single_test: single input test
```

## Environment Setup
This project was developed in Windows Subsystem Linux (WSL) with Ubuntu 22.04 LTS. **A native Linux installation is more preferred**. 

### FINN and Brevitas
To set up the environment for FINN and Brevitas, you can follow the official documentation provided by Xilinx ([FINN Doc](https://finn-dev.readthedocs.io/en/latest/) and [Brevitas Doc](https://xilinx.github.io/brevitas/v0.12.1/)). 

FINN requires to be operated within a Docker environment. This project built a docker engine from the following packages:
- `docker-ce-rootless-extras_26.1.4-1~ubuntu.22.04~jammy_amd64.deb `
- `docker-compose-plugin_2.27.1-1~ubuntu.22.04~jammy_amd64.deb `
- `docker-ce-cli_26.1.4-1~ubuntu.22.04~jammy_amd64.deb`
- `docker-ce_26.1.4-1~ubuntu.22.04~jammy_amd64.deb`
- `docker-buildx-plugin_0.14.1-1~ubuntu.22.04~jammy_amd64.deb`
- `containerd.io_1.6.33-1_amd64.deb`

The repository of FINN provides a ready-to-use shell script 
```bash
/path/to/finn/repo/run-docker.sh
```
 to automatically build a docker image, where contains all dependencies required to operating FINN, also Brevitas included. You need to specify some system variables to run this script
 - *FINN_XILINX_PATH*: a directory pointing to the path of Xilinx installation.
 - *FINN_XILINX_VERSION*: the version of Xilinx installation, for example 2023.2.
 - *PLATFORM_REPO_PATHS*: a directory pointing to the Vitis platform files (DSAs), only required when using Alveo PCIe cards.
 
 After running the script, you can use the command
 ```bash
 /path/to/finn/repo/run-docker.sh quicktest
 ```
to start a container and run the quick test example provided by FINN.

### Vivado and Vitis HLS
FINN relies on Vitis HLS for parts of the hardware generation process, especially when generating HLS-based accelerator components. After HLS synthesis, the generated IPs are further integrated and implemented in Vivado. 

For WSL users, FINN, Vivado, and Vitis HLS should be installed in the same system environment, such as WSL2 or a native Linux system. Cross-environment installation, for example placing FINN in WSL while keeping Vivado or Vitis HLS on the host system, may lead to tool invocation failures and cause the FINN workflow to behave unexpectedly. **Therefore, it is recommended to use a single and pure environment for this project.**