def dat_to_coe(input_file, output_file):
    with open(input_file, 'r') as f:
        data = [line.strip() for line in f if line.strip()]

    # 转为整数
    data = [int(x, 16) for x in data]

    # 4字节打包
    words = []
    for i in range(0, len(data), 4):
        word = 0
        for j in range(4):
            if i + j < len(data):
                word |= data[i + j] << (8 * j)  # little endian
        words.append(word)

    # 写 COE
    with open(output_file, 'w') as f:
        f.write("memory_initialization_radix=16;\n")
        f.write("memory_initialization_vector=\n")
        for i, w in enumerate(words):
            if i == len(words) - 1:
                f.write(f"{w:08X};\n")
            else:
                f.write(f"{w:08X},\n")

# 使用
dat_to_coe("../fyp/input.dat", "./mnist.coe")