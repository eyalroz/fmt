static_assert(__cplusplus >= 201402L, "The test for using fmt in CUDA kernel requires compiling the device-side code as C++14 or later");

#include <fmt/core.h>
//#include <fmt/chrono.h>

#include <stdio.h>

__device__ void initialize(char* buffer, size_t buffer_size)
{
  memset(buffer, buffer_size - 1, '@');
  buffer[buffer_size - 1] = '\0';
}

__global__ void printing_kernel()
{
#define QUOTE(str) #str
#define EXPAND_AND_QUOTE(str) QUOTE(str)
#define BUFFER_SIZE 32
#define BUFFER_SIZE_STR EXPAND_AND_QUOTE(BUFFER_SIZE)
  constexpr const auto buffer_size {BUFFER_SIZE};
  printf("Block %u thread %u: Running fmt tests\n", blockIdx.x, threadIdx.x);
  const char* s = "The quick brown fox jumped over the lazy dog";
  char buf[buffer_size + 1];
  initialize(buf, buffer_size);
  // Can't use this function, since it outputs an std::string, and we don't have
  // std::strings in kernels. We _could_ implement a string-like class (and maybe
  // even use it inside fmt), which could be returned in kernel-side.
  // fmt::format("{}", s);
  fmt::format_to(buf, "{}", s);
//  buf[buffer_size] = '\0'; // to be on the safe side
  printf("fmt::format_to(buf, " BUFFER_SIZE_STR ", \"{}\", \"%s\") results in: %." BUFFER_SIZE_STR "s\n", s, buf);

  initialize(buf, buffer_size);
  fmt::format_to(buf, FMT_STRING("{}"), s);
//  buf[buffer_size] = '\0'; // to be on the safe side
  printf("fmt::format_to(buf, " BUFFER_SIZE_STR ", \"{}\", \"%s\") results in: %." BUFFER_SIZE_STR "s\n", s, buf);

  initialize(buf, buffer_size);
  fmt::format_to_n(buf, buffer_size, "{}", s);
//  buf[buffer_size] = '\0'; // to be on the safe side
  printf("fmt::format_to_n(buf, " BUFFER_SIZE_STR ", \"{}\", \"%s\") results in: %." BUFFER_SIZE_STR "s\n", s, buf);

  initialize(buf, buffer_size);
  fmt::format_to_n(buf, buffer_size, "I'd rather be {1} than {0}.", "right", "happy");
  printf("fmt::format_to_n(buf, " BUFFER_SIZE_STR ", \"I'd rather be {1} than {0}.\", \"right\", \"happy\") results in: %." BUFFER_SIZE_STR "s\n", buf);

  initialize(buf, buffer_size);
  auto bsv = fmt::basic_string_view<char> { "This is my string_view" };
  fmt::format_to_n(buf, buffer_size, "{}", bsv);
  printf("fmt::format_to_n(buf, " BUFFER_SIZE_STR ", \"{}\", \"fmt::basic_string_view<char> { \"This is my string_view\" }) results in: %." BUFFER_SIZE_STR "s\n", buf);

//  using namespace std::literals::chrono_literals;
//  fmt::format_to_n(buf, buffer_size, "Default format: {} {}\n", 42s, 100ms);

  // These can't be used, since they target stdout - and our converted fmt has no access
  // to stdout. We _could_ implement those parts of it so that it eventually uses
  // the kernel-accessible "printf()" command though.
  //
  //    fmt::print("{}", s);
  //    fmt::print(stdout, "{}", s);
  //    for(int i = 0; i < sizeof(buf)/ sizeof(char); i++) {
  //      printf("%02x ", (int) buf[i]);
  //    }
  //    printf("Formatting commands buf = %*s\n", (int) (sizeof(buf) / sizeof(buf[0])), buf);
}

int main(void)
{
    int threadsPerBlock = 1;
    int blocksPerGrid = 1;
    printf("CUDA kernel launch with %d blocks of %d threads\n", blocksPerGrid, threadsPerBlock);
    printing_kernel<<<blocksPerGrid, threadsPerBlock>>>();
    auto err = cudaGetLastError();
    if (err != cudaSuccess) {
      fprintf(stderr, "Failed launching the printing kernel: %s\n", cudaGetErrorString(err));
      exit(EXIT_FAILURE);
    }
    err = cudaDeviceSynchronize();
    if (err != cudaSuccess) {
      fprintf(stderr, "printing kernel execution failed: %s\n", cudaGetErrorString(err));
      exit(EXIT_FAILURE);
    }
}
