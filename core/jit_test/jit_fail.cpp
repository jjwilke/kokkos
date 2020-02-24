#include <Kokkos_Core.hpp>

template <class View>
struct MemsetFunctor {
  View v;
  MemsetFunctor(const View& _v) : v(_v) {}
  void operator()(const size_t idx) const {
    v(idx) = double(idx); 
  }
};

template <class View>
struct ReduceFunctor {
  View v;
  ReduceFunctor(const View& _v) : v(_v) {}
  void operator()(const size_t idx, double& update) const {
    update += v(idx);
  }
};

template <int Size, class View>
[[clang::jit]]
double run(const View& v)
{
  MemsetFunctor<View> f(v);
  Kokkos::parallel_for(Size, f);
  double result = 0;
  ReduceFunctor<View> g(v);
  Kokkos::parallel_reduce(Size, g, result);
  Kokkos::fence();
  return result;
}

int main(int argc, char** argv)
{
  int sz = 100;
  Kokkos::initialize();
  {
    Kokkos::View<double*> test("test", sz);
    double ans = run<sz>(test);
    std::cout << "Result = " << ans << std::endl;
  }
  Kokkos::finalize();
  return 0;
}
