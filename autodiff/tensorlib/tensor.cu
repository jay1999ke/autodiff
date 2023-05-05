#include "tensor.h"
#define THREADSPERBLOCK 512

Tensor *createGPUTensor(size_t rows, size_t cols) {
    Tensor *tensor = new Tensor(rows, cols);
    tensor->gpu_alloc();
    tensor->setOnGpu(true);
    return tensor;
}

void Tensor::setOnGpu(bool val) { on_gpu = val; }

void Tensor::gpu_alloc() {
    if (gpu_data == nullptr)
        cudaMalloc(&gpu_data, size());
}

void Tensor::gpu() {
    gpu_alloc();
    cudaMemcpy(dataGpu(), data(), size(), cudaMemcpyHostToDevice);
    setOnGpu(true);
}

void Tensor::cpu() {
    if (dataGpu() != nullptr)
        cudaMemcpy(data(), dataGpu(), size(), cudaMemcpyDeviceToHost);
}

void Tensor::maintain() {
    if (on_gpu) {
        if (dataGpu() != nullptr)
            cudaMemcpy(data(), dataGpu(), size(), cudaMemcpyDeviceToHost);
    } else {
        if (dataGpu() != nullptr)
            cudaMemcpy(dataGpu(), data(), size(), cudaMemcpyHostToDevice);
    }
}

void Tensor::gpuFree() {
    if (dataGpu() != nullptr)
        cudaFree(dataGpu());
    gpu_data = nullptr;
    setOnGpu(false);
}

void gpu_set_zero(Tensor *a) { cudaMemset(a->dataGpu(), 0, a->size()); }

Tensor *gpu_add(Tensor *a, Tensor *b) {
    a->onGpuAssert();
    b->onGpuAssert();
    a->sameShapeAssert(b);

    py::buffer_info a_info = a->request();
    py::buffer_info b_info = b->request();

    int dim0 = a_info.shape[0];
    int dim1 = a_info.shape[1];

    Tensor *result = createGPUTensor(dim0, dim1);

    
    int blocks = (result->size() + THREADSPERBLOCK - 1) / THREADSPERBLOCK;

    _add<<<blocks, THREADSPERBLOCK>>>(a->dataGpu(), b->dataGpu(),
                                      result->dataGpu(), dim0, dim1);

    return result;
}

Tensor *gpu_sub(Tensor *a, Tensor *b) {
    a->onGpuAssert();
    b->onGpuAssert();
    a->sameShapeAssert(b);

    py::buffer_info a_info = a->request();
    py::buffer_info b_info = b->request();

    int dim0 = a_info.shape[0];
    int dim1 = a_info.shape[1];

    Tensor *result = createGPUTensor(dim0, dim1);

    
    int blocks = (result->size() + THREADSPERBLOCK - 1) / THREADSPERBLOCK;

    _sub<<<blocks, THREADSPERBLOCK>>>(a->dataGpu(), b->dataGpu(),
                                      result->dataGpu(), dim0, dim1);

    return result;
}

Tensor *gpu_neg(Tensor *a) {
    a->onGpuAssert();

    py::buffer_info a_info = a->request();

    int dim0 = a_info.shape[0];
    int dim1 = a_info.shape[1];

    Tensor *result = createGPUTensor(dim0, dim1);

    
    int blocks = (result->size() + THREADSPERBLOCK - 1) / THREADSPERBLOCK;

    _neg<<<blocks, THREADSPERBLOCK>>>(a->dataGpu(), result->dataGpu(), dim0,
                                      dim1);

    return result;
}

Tensor *gpu_mul(Tensor *a, Tensor *b) {
    a->onGpuAssert();
    b->onGpuAssert();
    a->sameShapeAssert(b);

    py::buffer_info a_info = a->request();
    py::buffer_info b_info = b->request();

    int dim0 = a_info.shape[0];
    int dim1 = a_info.shape[1];

    Tensor *result = createGPUTensor(dim0, dim1);

    
    int blocks = (result->size() + THREADSPERBLOCK - 1) / THREADSPERBLOCK;

    _mul<<<blocks, THREADSPERBLOCK>>>(a->dataGpu(), b->dataGpu(),
                                      result->dataGpu(), dim0, dim1);

    return result;
}

Tensor *gpu_div(Tensor *a, Tensor *b) {
    a->onGpuAssert();
    b->onGpuAssert();
    a->sameShapeAssert(b);

    py::buffer_info a_info = a->request();
    py::buffer_info b_info = b->request();

    int dim0 = a_info.shape[0];
    int dim1 = a_info.shape[1];

    Tensor *result = createGPUTensor(dim0, dim1);

    
    int blocks = (result->size() + THREADSPERBLOCK - 1) / THREADSPERBLOCK;

    _div<<<blocks, THREADSPERBLOCK>>>(a->dataGpu(), b->dataGpu(),
                                      result->dataGpu(), dim0, dim1);

    return result;
}

Tensor *gpu_sum(Tensor *a, int axis) {
    a->onGpuAssert();

    py::buffer_info a_info = a->request();

    int dim0 = a_info.shape[0];
    int dim1 = a_info.shape[1];

    int res_dim0, res_dim1;

    if (axis == 0) {
        res_dim0 = 1;
        res_dim1 = dim1;
    } else if (axis == 1) {
        res_dim0 = dim0;
        res_dim1 = 1;
    } else {
        throw std::runtime_error("Invalid sum axis");
    }

    Tensor *result = createGPUTensor(res_dim0, res_dim1);

    
    int blocks = (result->size() + THREADSPERBLOCK - 1) / THREADSPERBLOCK;

    _sum<<<blocks, THREADSPERBLOCK>>>(a->dataGpu(), result->dataGpu(), dim0,
                                      dim1, axis);

    return result;
}

Tensor *gpu_bct(Tensor *a, int axis, int dim) {
    a->onGpuAssert();

    py::buffer_info a_info = a->request();

    int dim0 = a_info.shape[0];
    int dim1 = a_info.shape[1];

    int res_dim0, res_dim1;

    if (axis == 0) {
        res_dim0 = dim;
        res_dim1 = dim1;
    } else if (axis == 1) {
        res_dim0 = dim0;
        res_dim1 = dim;
    } else {
        throw std::runtime_error("Invalid sum axis");
    }

    Tensor *result = createGPUTensor(res_dim0, res_dim1);

    
    int blocks = (result->size() + THREADSPERBLOCK - 1) / THREADSPERBLOCK;

    _bct<<<blocks, THREADSPERBLOCK>>>(a->dataGpu(), result->dataGpu(), res_dim0,
                                      res_dim1, axis);

    return result;
}

Tensor *gpu_cpy(Tensor *a) {
    a->onGpuAssert();

    py::buffer_info a_info = a->request();

    int dim0 = a_info.shape[0];
    int dim1 = a_info.shape[1];
    size_t size = a->size();

    Tensor *result = createGPUTensor(dim0, dim1);

    cudaMemcpy(result->dataGpu(), a->dataGpu(), size, cudaMemcpyDeviceToDevice);

    return result;
}

Tensor *gpu_exp(Tensor *a) {
    a->onGpuAssert();

    py::buffer_info a_info = a->request();

    int dim0 = a_info.shape[0];
    int dim1 = a_info.shape[1];
    size_t size = a->size();

    Tensor *result = createGPUTensor(dim0, dim1);

    
    int blocks = (result->size() + THREADSPERBLOCK - 1) / THREADSPERBLOCK;

    _exp<<<blocks, THREADSPERBLOCK>>>(a->dataGpu(), result->dataGpu(), dim0,
                                      dim1);

    return result;
}

Tensor *gpu_log(Tensor *a) {
    a->onGpuAssert();

    py::buffer_info a_info = a->request();

    int dim0 = a_info.shape[0];
    int dim1 = a_info.shape[1];
    size_t size = a->size();

    Tensor *result = createGPUTensor(dim0, dim1);

    
    int blocks = (result->size() + THREADSPERBLOCK - 1) / THREADSPERBLOCK;

    _log<<<blocks, THREADSPERBLOCK>>>(a->dataGpu(), result->dataGpu(), dim0,
                                      dim1);

    return result;
}

Tensor *gpu_tsp(Tensor *a) {
    a->onGpuAssert();

    py::buffer_info a_info = a->request();

    int dim0 = a_info.shape[0];
    int dim1 = a_info.shape[1];
    size_t size = a->size();

    Tensor *result = createGPUTensor(dim1, dim0);

    
    int blocks = (result->size() + THREADSPERBLOCK - 1) / THREADSPERBLOCK;

    _tsp<<<blocks, THREADSPERBLOCK>>>(a->dataGpu(), result->dataGpu(), dim0,
                                      dim1);

    return result;
}

Tensor *gpu_pow(Tensor *a, float val) {
    a->onGpuAssert();

    py::buffer_info a_info = a->request();

    int dim0 = a_info.shape[0];
    int dim1 = a_info.shape[1];
    size_t size = a->size();

    Tensor *result = createGPUTensor(dim0, dim1);

    
    int blocks = (result->size() + THREADSPERBLOCK - 1) / THREADSPERBLOCK;

    _pow<<<blocks, THREADSPERBLOCK>>>(a->dataGpu(), result->dataGpu(), dim0,
                                      dim1, val);

    return result;
}

Tensor *gpu_relu(Tensor *a) {
    a->onGpuAssert();

    int dim0 = a->rows();
    int dim1 = a->cols();
    size_t size = a->size();

    Tensor *result = createGPUTensor(dim0, dim1);

    
    int blocks = (result->size() + THREADSPERBLOCK - 1) / THREADSPERBLOCK;

    _relu<<<blocks, THREADSPERBLOCK>>>(a->dataGpu(), result->dataGpu(), dim0,
                                       dim1);

    return result;
}

Tensor *gpu_relu_grad(Tensor *a, Tensor *grad) {
    a->onGpuAssert();
    grad->onGpuAssert();
    a->sameShapeAssert(grad);

    int dim0 = a->rows();
    int dim1 = a->cols();
    size_t size = a->size();

    Tensor *result = createGPUTensor(dim0, dim1);

    
    int blocks = (result->size() + THREADSPERBLOCK - 1) / THREADSPERBLOCK;

    _relu_grad<<<blocks, THREADSPERBLOCK>>>(a->dataGpu(), grad->dataGpu(),
                                            result->dataGpu(), dim0, dim1);

    return result;
}

Tensor *gpu_matmul(Tensor *a, Tensor *b) {
    a->onGpuAssert();
    b->onGpuAssert();

    if (a->cols() != b->rows()) {
        throw std::runtime_error("Incompatible shape for matmul");
    }

    int dim0_a = a->rows();
    int dim1_a = a->cols();
    int dim1_b = b->cols();

    Tensor *result = createGPUTensor(dim0_a, dim1_b);

    
    int blocks = (result->size() + THREADSPERBLOCK - 1) / THREADSPERBLOCK;

    _matmul<<<blocks, THREADSPERBLOCK>>>(
        a->dataGpu(), b->dataGpu(), result->dataGpu(), dim0_a, dim1_a, dim1_b);

    return result;
}

std::vector<Tensor *> gpu_max(Tensor *a, int axis) {
    a->onGpuAssert();

    int dim0 = a->rows();
    int dim1 = a->cols();

    int res_dim0, res_dim1;

    if (axis == 0) {
        res_dim0 = 1;
        res_dim1 = dim1;
    } else if (axis == 1) {
        res_dim0 = dim0;
        res_dim1 = 1;
    } else {
        throw std::runtime_error("Invalid max axis");
    }

    Tensor *max = createGPUTensor(res_dim0, res_dim1);
    Tensor *idx = createGPUTensor(res_dim0, res_dim1);

    
    int blocks = (max->size() + THREADSPERBLOCK - 1) / THREADSPERBLOCK;

    _max<<<blocks, THREADSPERBLOCK>>>(a->dataGpu(), max->dataGpu(),
                                      idx->dataGpu(), dim0, dim1, axis);

    std::vector<Tensor *> result;
    result.push_back(max);
    result.push_back(idx);

    return result;
}

Tensor *gpu_axial_mask(Tensor *a, Tensor *idx, int axis) {
    a->onGpuAssert();

    int dim0 = a->rows();
    int dim1 = a->cols();

    Tensor *result = createGPUTensor(dim0, dim1);

    
    int blocks = (idx->size() + THREADSPERBLOCK - 1) / THREADSPERBLOCK;

    cudaMemset(result->dataGpu(), 0, result->size());

    _axial_mask<<<blocks, THREADSPERBLOCK>>>(result->dataGpu(), idx->dataGpu(),
                                             dim0, dim1, axis);

    return result;
}
