## {fmt} + CUDA Support


[**{fmt}**](https://github.com/fmtlib/fmt) is an open-source formatting library providing a fast and safe
alternative to C stdio and C++ iostreams. This **fork of {fmt}** adds support for CUDA device-side use of {fmt}, 
mostly for debugging your kernels and device-side functions. It does not involve any collaboration
between kernel threads - simply making it possible for individual CUDA threads (one, many or all) to format
strings using the {fmt} library facilities.

If you like this project, please consider donating to [Anarchist Black Cross Belarus](https://abc-belarus.org/?lang=en)
Belarus, which supports Anarchist and anti-Fascist political prisoners and detainees in Belarus, especially
following the 2020 uprising. [Link to the donation page](https://abc-belarus.org/?page_id=8661&lang=en); they take
PayPal and you can get their bank account. They also take BitCoin but I (eyalroz) don't approve of that.

The original repository's author suggests donating to a more general fund supporting victims of political repressions in Belarus:
https://bysol.org/en/bs/general/.

[Original {fmt} Documentation](https://fmt.dev)

[Q&A]: 

* Ask questions on [StackOverflow with the tags fmt and cuda](https://stackoverflow.com/questions/tagged/fmt+cuda), 
* If the question is about a potential feature / bug, open an [issue](/eyalroz/fmt/issues/).

Features
========

-   Simple [format API](https://fmt.dev/latest/api.html) with positional arguments for localization
-   Implementation of [C++20 std::format](https://en.cppreference.com/w/cpp/utility/format)
-   [Format string syntax](https://fmt.dev/latest/syntax.html) similar to Python's [format](https://docs.python.org/3/library/stdtypes.html#str.format)
-   Fast IEEE 754 floating-point formatter with correct rounding, shortness and round-trip guarantees
-   Safe [printf implementation](https://fmt.dev/latest/api.html#printf-formatting) including the POSIX extension for positional arguments
-   Extensibility: [support for user-defined types](https://fmt.dev/latest/api.html#formatting-user-defined-types)
-   High performance of the host-side code (see the [fmt repo](https://github.com/fmtlib/fmt))
-   Small code size both in terms of source code with the minimum configuration consisting of just three files, `core.h`, `format.h` and `format-inl.h`, and compiled code.
-   Reliability - of the host side code, which passes the fmt library's suite of testcases. Device-side is still in development, but hopefully will eventually pass all
    those tests (except the tests involving host-only features)
-   Safety: the library should be fully type safe, errors in format strings can be reported at compile time, automatic memory management prevents buffer overflow errors.
    (Not 100% sure about buffer overflow prevention in device-side cude).
-   Ease of use: small self-contained code base, no external dependencies, permissive MIT [license](https://github.com/fmtlib/fmt/blob/master/LICENSE.rst)
-   Clean warning-free codebase even on high warning levels such as `-Wall -Wextra -pedantic`
-   Currently, only header-only mode is supported; this may change in the future.

See the [fmt documentation](https://fmt.dev) for more details - but only on those features shared with fmt.

Examples
========

See [{fmt}'s Examples](https://github.com/fmtlib/fmt#examples) for what you can do in host-side code. On the device side, you can...


**"Print" into a buffer** 

``` {.sourceCode .cu}
#include <fmt/core.h>

__device__ example1() {
  constexpr const auto buffer_size {50};
  char buffer[buffer_size];
  // unsafe version assume size is sufficient:
  fmt::format_to(buffer, "Hello, world!\n");

  // less-unsafe version does not exceed size (but doesn't
  // append a terminating NUL character either!)
  fmt::format_to_n(buffer, buffer_size, "Hello, world!\n");
}
```

**Format a string** 

``` {.sourceCode .cu}
fmt::format_to_n(buffer, buffer_size, "The answer is {}.", 42);
```

**Format a string using positional arguments**

``` {.sourceCode .cu}
fmt::format_to_n(buffer, buffer_size, "I'd rather be {1} than {0}.", "right", "happy");
// buffer contains "I'd rather be happy than right." (but no final '\0'
```

**Print chrono durations**

(Doesn't work yet.)

``` {.sourceCode .cu}
#include <fmt/chrono.h>

using namespace std::literals::chrono_literals;
fmt::format_to_n(buffer, buffer_size, "Default format: {} {}\n", 42s, 100ms);
// buffer now contains "Default format: 42s 100ms"
fmt::format_to_n(buffer, buffer_size, "strftime-like format: {:%H:%M:%S}\n", 3h + 15min + 30s);
// buffer now contains "strftime-like format: 03:15:30"
}
```

**Print a container** 

``` {.sourceCode .cu}
#include <kat/containers/array.cuh>
#include <fmt/ranges.h>

kat::array<int, 3> a = {1, 2, 3};
fmt::format_to_n(buf, buffer_size, "{}\n", a);
// buf now contains: "[1, 2, 3]"
```

**Check a format string at compile time**

``` {.sourceCode .cu}
fmt::format_to_n(buf, buffer_size, FMT_STRING("{:d}"), "I am not a number");
```

This should give a compile-time error because `d` is an invalid format specifier for a string (... but is not yet tested.)

Benchmarks
==========

No benchmarking has been carried out yet on this fork, neither on the host-side nor the device-side.

Compile time and code bloat
---------------------------

(Not yet examined)

Running the tests
-----------------

Please refer to [Building the library](https://fmt.dev/latest/usage.html#building-the-library) for the instructions on how to build the library and run the unit tests. You must ensure the CUDA tests are enabled (and, naturally, that you have a working CUDA installation, an appropriate NVIDIA driver, a working GPU etc.)

Migrating code
==============

For now, it is impossible to migrate `printf()`-based code to `fmt`-based code within CUDA kernels, as an `fmt::print()` function based on underlying `printf()` calls is [not yet available](https://github.com/eyalroz/fmt/issues/2).

Projects using this library
===========================

If you are using this library in a project of yours, please let me know by [email](mailto:eyalroz1@gmx.com) or by submitting an [issue](https://github.com/fmtlib/fmt/issues).

Motivation
==========

CUDA's printf() is nice, but:

1. It becomes effectively unusable when you're writing templated code. We must have a variadic-templated formatting function (well, either that or an ostream-like mechanism). 
2. There is no `sprintf()` on the GPU, and `printf()` can't be adapted into one. So a buffer-targeting string formatter is necessary.
3. `printf()` has safety issues. A more C++'ish formatter can catch more problems at compile-time and prevent kernel crashes or hangs (which you might not realize are because of a printing issue).

fmt provides these things for host-side C++ code, and it's pretty robust and popular, so - it's an obvious choice. Unfortunately, fmt's maintainer is not currently interested in adding CUDA support into fmt itself, so I had to fork.

License
=======

This fork, like {fmt} itself, is distributed under the MIT [license](https://github.com/fmtlib/fmt/blob/master/LICENSE.rst).

Maintainers
===========

This fork is being developed by [Eyal Rozenberg](https://eyalroz.github.io/) ([eyalroz](https://github.com/eyalroz/) on GitHub). Help, even with testing, would be very much appreciated.

The {fmt} library is maintained by Victor Zverovich ([vitaut](https://github.com/vitaut)) and Jonathan Müller ([foonathan](https://github.com/foonathan)) with contributions from many other people.

