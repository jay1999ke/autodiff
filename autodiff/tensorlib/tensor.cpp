#include "tensor.h"

std::string Tensor::repr() {
    if(on_gpu)
        cpu();
    std::string str = "tensor([";
    for (int i = 0; i < dim0; i++) {
        if (i != 0)
            str += ",\n        ";
        str += "[";
        for (int j = 0; j < dim1; j++) {
            if (j != 0)
                str += ", ";
            std::ostringstream strs;
            strs << std::fixed << std::setprecision(3)
                 << cpu_data[i * dim1 + j];
            str += strs.str();
        }
        str += "]";
    }
    if (on_gpu)
        str += "], gpu = True)";
    else
        str += "])";
    return str;
};

Tensor* cpu_add(Tensor *a, Tensor *b) {
    a->onCpuAssert();
    b->onCpuAssert();

    py::buffer_info a_info = a->request();
    py::buffer_info b_info = b->request();

    if (a_info.shape.size() != b_info.shape.size()) {
        throw std::runtime_error("Dimentions don't match");
    }

    if (a_info.shape.size() != 2) {
        throw std::runtime_error("Only 2D tensors supported");
    }

    auto a_ptr = static_cast<float *>(a_info.ptr);
    auto b_ptr = static_cast<float *>(b_info.ptr);

    int dim1 = a_info.shape[0];
    int dim2 = a_info.shape[1];

    Tensor *result = new Tensor(dim1, dim2); // create an object on the heap
    float *res_ptr = result->data();

    for (int i = 0; i < dim1; i++) {
        for (int j = 0; j < dim2; j++) {
            res_ptr[i * dim1 + j] = a_ptr[i * dim1 + j] + b_ptr[i * dim1 + j];
        }
    }

    return result;
}