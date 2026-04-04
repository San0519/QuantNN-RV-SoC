import gzip
import struct


def read_images_gz(path):
    with gzip.open(path, "rb") as f:
        magic, count, rows, cols = struct.unpack(">IIII", f.read(16))
        if magic != 2051:
            raise ValueError(f"bad image magic: {magic}")
        data = f.read(count * rows * cols)
    return count, rows, cols, data


def read_labels_gz(path):
    with gzip.open(path, "rb") as f:
        magic, count = struct.unpack(">II", f.read(8))
        if magic != 2049:
            raise ValueError(f"bad label magic: {magic}")
        data = f.read(count)
    return count, data


def bytes_to_dat(byte_list, out_path):
    with open(out_path, "w") as f:
        for b in byte_list:
            f.write(f"{b:02X}\n")


def labels_to_dat(label_list, out_path):
    with open(out_path, "w") as f:
        for b in label_list:
            f.write(f"{b:02X}\n")


def bytes_to_coe(byte_list, out_path):
    words = []
    for i in range(0, len(byte_list), 4):
        word = 0
        for j in range(4):
            if i + j < len(byte_list):
                word |= byte_list[i + j] << (8 * j)
        words.append(word)

    with open(out_path, "w") as f:
        f.write("memory_initialization_radix=16;\n")
        f.write("memory_initialization_vector=\n")
        for i, w in enumerate(words):
            end = ";\n" if i == len(words) - 1 else ",\n"
            f.write(f"{w:08X}{end}")


def export_mnist_subset(
    images_gz,
    labels_gz,
    out_image_dat,
    out_label_dat,
    out_coe,
    max_samples=None,
):
    img_count, rows, cols, img_bytes = read_images_gz(images_gz)
    lbl_count, lbl_bytes = read_labels_gz(labels_gz)

    if rows != 28 or cols != 28:
        raise ValueError(f"unexpected image shape: {rows}x{cols}")
    if img_count != lbl_count:
        raise ValueError(f"image/label count mismatch: {img_count} vs {lbl_count}")

    total = img_count if max_samples is None else min(max_samples, img_count)
    one_image = rows * cols

    selected_images = img_bytes[: total * one_image]
    selected_labels = lbl_bytes[:total]

    bytes_to_dat(selected_images, out_image_dat)
    labels_to_dat(selected_labels, out_label_dat)
    bytes_to_coe(selected_images, out_coe)

    print(f"exported samples: {total}")
    print(f"image bytes: {len(selected_images)}")
    print(f"label bytes: {len(selected_labels)}")
    print(f"images dat: {out_image_dat}")
    print(f"labels dat: {out_label_dat}")
    print(f"coe: {out_coe}")


if __name__ == "__main__":
    export_mnist_subset(
        images_gz="t10k-images-idx3-ubyte.gz",
        labels_gz="t10k-labels-idx1-ubyte.gz",
        out_image_dat="mnist_t10k.dat",
        out_label_dat="mnist_t10k_labels.dat",
        out_coe="mnist_t10k.coe",
        max_samples=64,
    )