# LVGL TinyTTF Performance Optimization

> **Academic Project**: This work was completed as part of the High Performance Computing (HPC) coursework at HEIG-VD, focusing on real-world performance optimization of open-source software.

This project demonstrates performance optimization of the LVGL (Light and Versatile Graphics Library) TinyTTF font rendering component. Through profiling-driven optimization, we achieved a **24x improvement** in rendering performance by implementing kerning cache functionality.

## Project Objectives

As part of the HPC coursework, this project aimed to:

- **Identify performance bottlenecks** in an open-source library using profiling tools
- **Apply optimization techniques** learned in the course to real-world software
- **Measure and validate improvements** with quantitative performance analysis
- **Contribute back to the open-source community** through upstream pull requests
- **Demonstrate the importance of data-driven optimization** over intuition-based approaches

## Quick Start

### Prerequisites

Install SDL2 development libraries:

**Ubuntu/Debian:**

```bash
sudo apt install libsdl2-dev libsdl2-image-dev
```

**Fedora:**

```bash
sudo dnf install SDL2-devel SDL2_image-devel
```

### Build

```bash
# Clone and build the project
cmake -B build -S . -DCMAKE_BUILD_TYPE=Release
cmake --build build -j$(nproc)
```

### Run Demo Applications

Two demo applications are built to showcase the performance difference:

**Optimized version (with kerning cache):**

```bash
./build/bin/tiny_ttf_demo_cache
```

**Original version (without kerning cache):**

```bash
./build/bin/tiny_ttf_demo_no_cache
```

**Performance benchmarking (first render only):**

```bash
hyperfine --warmup 10 "./build/bin/tiny_ttf_demo_cache --first-render-only"
hyperfine --warmup 10 "./build/bin/tiny_ttf_demo_no_cache --first-render-only"
```

## Performance Results

| Metric              | Original | Optimized | Improvement     |
| ------------------- | -------- | --------- | --------------- |
| First render time   | ~214ms   | ~9ms      | **24x faster**  |
| Application startup | ~937ms   | ~276ms    | **3.4x faster** |
| Frame rate          | ~9.5 FPS | ~250 FPS  | **26x faster**  |
| Average frame time  | ~105ms   | ~4ms      | **26x faster**  |

## Project Structure

```
├── src/main.c                    # Demo application source
├── CMakeLists.txt               # Build configuration
├── lv_conf_cache.h             # LVGL config with kerning cache
├── lv_conf_no_cache.h          # LVGL config without kerning cache
├── myriadpro.ttf               # Test font with extensive kerning data
├── docs                        # Documentation and presentation
└── build/bin/                  # Built demo applications
    ├── tiny_ttf_demo_cache     # Optimized version
    └── tiny_ttf_demo_no_cache  # Original version
```

## Contributing

This project was developed as part of the High Performance Computing coursework. The optimization has been contributed back to the LVGL project via pull request [#8320](https://github.com/lvgl/lvgl/pull/8320).

## License

This project follows the same license as LVGL (MIT License).
