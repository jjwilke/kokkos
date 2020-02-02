#include <Kokkos_Core.hpp>

template <class View>
struct MemsetFunctor {
  View v;
  MemsetFunctor(const View& _v) : v(_v) {}
  void operator()(const size_t idx) const {
    v(idx) = 0.;
  }
};

template <int Size, class View>
[[clang::jit]] 
void run(const View& v)
{
  MemsetFunctor<View> f(v);
  Kokkos::parallel_for(Size, f);
  Kokkos::fence();
}

int main(int argc, char** argv)
{
  int sz = 1000;
  Kokkos::initialize();
  {
    Kokkos::View<double*> test("test", sz);
    run<sz>(test);
  }
  Kokkos::finalize();
  return 0;
}
