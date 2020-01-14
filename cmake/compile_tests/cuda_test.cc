#include <cuda_runtime.h>
#include <cstdio>
#include <Kokkos_Macros.hpp>

int main()
{
  int count = 0;
  if (cudaSuccess != cudaGetDeviceCount(&count)) return -1;
  if (count == 0) return -1;
  bool okay = true;
  for (int device = 0; device < count; ++device){
    cudaDeviceProp prop;
    if (cudaSuccess == cudaGetDeviceProperties(&prop, device)){
      int version = 10*prop.major + prop.minor;
      if (version > KOKKOS_CUDA_ARCH_NUMBER) {
        std::printf("Found compute capability %d, which is greater than requested %d\n",
                    version, KOKKOS_CUDA_ARCH_NUMBER);
      } else if (version == KOKKOS_CUDA_ARCH_NUMBER) {
        std::printf("Found compute capability %d, which is equal to requested %d\n",
                    version, KOKKOS_CUDA_ARCH_NUMBER);
      } else {
        std::printf("Found compute capability %d, which is lower than requested %d\n",
                    version, KOKKOS_CUDA_ARCH_NUMBER);
        okay = false;
      }
    } else {
      okay = false;
    }
  }
  if (okay){
    std::printf("Validation passed\n");
    return 0;
  } else {
    std::printf("Validation failed\n");
    return 0;
  }
}
