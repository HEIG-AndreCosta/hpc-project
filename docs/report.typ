#include "title.typ"

#pagebreak()

#outline(title: "Table of Contents", depth: 3, indent: 15pt)

#pagebreak()

= Introduction

This report documents the performance optimization of an open-source library as part of the High Performance Computing coursework.
The selected library was LVGL (Light and Versatile Graphics Library), specifically targeting the TinyTTF wrapper component responsible for font rendering operations.

#link("https://lvgl.io/")[LVGL] is a popular embedded graphics library that provides a comprehensive GUI framework for microcontrollers and small processors.
The TinyTTF wrapper serves as an integration layer between LVGL and the STB TrueType font library, unifying font operations under LVGL's API.

Initial performance testing revealed significant rendering bottlenecks when using the MyriadPro font, with individual frame render times exceeding 100ms,
making the interface unresponsive for practical applications.

During the course of this project, a PR was open in LVGL's Github. You can find it #link("https://github.com/lvgl/lvgl/pull/8320")[here].

= Getting Started

== Prerequisites

This project requires SDL2 development libraries to run the demonstration application. Install the required dependencies on your system:

*Ubuntu/Debian:*

```bash
sudo apt install libsdl2-dev libsdl2-image-dev
```

*Fedora:*

```bash
sudo dnf install SDL2-devel SDL2_image-devel
```

== Building the project

The project uses CMake and is configured to build two versions of the demonstration application - one with kerning cache optimization enabled and
another with the original unoptimized implementation for performance comparison.

Build the project using the following commands:

```bash
cmake -B build -S . -DCMAKE_BUILD_TYPE=Release
cmake --build build -j$(nproc)
```

This will generate two executables in the `build/bin/` directory:
- `tiny_ttf_demo_cache`: Optimized version with kerning caching
- `tiny_ttf_demo_no_cache`: Original version without kerning caching

== Running the demonstration

The demonstration application displays scrolling Lorem Ipsum text using the MyriadPro font to showcase the performance difference between the optimized and original implementations.

*Interactive Mode (Continuous Scrolling):*
```bash
./build/bin/tiny_ttf_demo_cache
./build/bin/tiny_ttf_demo_no_cache
```

*First Render Only Mode:*
For precise timing measurements, use the `--first-render-only` flag to exit after the initial render:
```bash
./build/bin/tiny_ttf_demo_cache --first-render-only
./build/bin/tiny_ttf_demo_no_cache --first-render-only
```

This mode is particularly useful for benchmarking startup performance using tools like `time` or `hyperfine`:
```bash
time ./build/bin/tiny_ttf_demo_no_cache --first-render-only
time ./build/bin/tiny_ttf_demo_cache --first-render-only
```

The performance difference between the two versions should be immediately apparent, with the optimized version demonstrating significantly reduced startup times and smoother scrolling animation.

= Typography fundamentals

Before diving into the performance optimization, let's quickly cover the basic concepts that are essential to understand what we're optimizing.

== Font

A font is basically a collection of characters that all look similar - think Arial, Times New Roman, etc. Each font contains:

- All the letters, numbers, and symbols you can type
- Information about how big each character should be
- Spacing rules between characters
- Style information (bold, italic, etc.)

Modern fonts are pretty sophisticated - they don't just store what letters look like, but also a ton of metadata about how to render them properly.

== Glyph

A glyph is simply the visual representation of a character in a specific font. While "character" and "glyph" are often used interchangeably, they're technically different:

- Character: The abstract concept (like "the letter A")
- Glyph: How that letter actually looks in a particular font

Each glyph contains:
- The actual shape/outline of the character
- Size and positioning information
- How much horizontal space it takes up

== Kerning

Kerning is where things get interesting for our optimization story. It's the process of adjusting spacing between specific letter pairs to make text look better.

Without kerning, letters are just placed next to each other with uniform spacing, which often looks terrible. For example:
- "AV" - these letters have diagonal edges that create awkward whitespace
- "To" - the lowercase "o" can actually fit partially under the "T"
- "We" - similar deal with the "e" fitting under the "W"

Here's the kicker: professional fonts can have kerning data for 10,000+ character pairs. That's a lot of lookups, and as we'll see, this is exactly where our performance bottleneck was hiding.

Every time you render text, the system has to check: "Do these two characters need special spacing?" This lookup happens for every single character pair in your text.


= Performance analysis and problem identification

=== Initial performance baseline

Performance measurements were conducted with the provided application.

Using hyperfine to calculate the time it takes for the first render to complete we can see that it takes about 1 second to show something on the screen 
which is not acceptable from a user experience standpoint, as users expect near-instant feedback.

```bash
hyperfine --warmup 10 "./build/bin/tiny_ttf_demo_no_cache --first-render-only"
Benchmark 1: ./build/bin/tiny_ttf_demo_no_cache --first-render-only
  Time (mean ± σ):     937.0 ms ±  12.7 ms    [User: 395.6 ms, System: 504.9 ms]
  Range (min … max):   923.8 ms … 967.7 ms    10 runs
```

Then, by isolating the rendering time by checking the time elapsed inside the application, we can see that it takes around ~214ms on average.

```bash
 ❯ ./build/bin/tiny_ttf_demo_no_cache
[User]	(0.916, +916)	main: Time for first render (rendering + layout) 262 ms
[User]	(1.128, +212)	main: Time for rendering only (no layout) 212 ms
❯ ./build/bin/tiny_ttf_demo_no_cache
[User]	(0.950, +950)	main: Time for first render (rendering + layout) 271 ms
[User]	(1.164, +214)	main: Time for rendering only (no layout) 214 ms
❯ ./build/bin/tiny_ttf_demo_no_cache
[User]	(0.927, +927)	main: Time for first render (rendering + layout) 266 ms
[User]	(1.140, +213)	main: Time for rendering only (no layout) 213 ms
❯ ./build/bin/tiny_ttf_demo_no_cache
[User]	(0.959, +959)	main: Time for first render (rendering + layout) 267 ms
[User]	(1.177, +218)	main: Time for rendering only (no layout) 218 ms
```

And when we run the application we can see an average render time of ~105ms per frame

#figure(image("./media/original_render_time_running_app.png", width: 50%), caption:[Render time during application execution])

These performance figures indicated severe optimization opportunities, particularly for interactive applications requiring smooth frame rates.

=== Profiling with flame graphs

Flame graph analysis revealed the performance bottleneck concentrated in a single function: `stbtt_GetGlyphKernAdvance`.
This function, responsible for calculating kerning values between glyph pairs, consumed approximately 50% of total CPU cycles during the application startup phase until the first render.

#figure(image("./media/original_fg.png", width: 50%), caption:[Original flamegraph])

The flame graph clearly illustrated that kerning calculations were being performed repeatedly for the same glyph pairs,
indicating a lack of result caching for this computationally expensive operation.

=== Root cause analysis

While LVGL's tinyttf library already handled font and glyph caching effectively,
kerning calculations were performed on-demand for every rendering operation.

Kerning calculation involves:
1. Font table lookups
2. Glyph pair matching
3. Mathematical calculations for spacing adjustments
4. File read operations

Without caching, identical glyph pairs required full recalculation during each render cycle,
creating unnecessary computational overhead particularly noticeable with fonts containing extensive kerning tables like MyriadPro.

== Optimization strategy

=== Approach

The optimization leveraged LVGL's existing cache infrastructure to implement kerning value caching. This approach offered several advantages:

- *Consistency*: Utilized the same red-black tree cache mechanism already proven effective for font and glyph caching
- *Memory management*: Benefited from LVGL's existing cache eviction policies and memory management
- *Integration*: Minimal code changes required, maintaining library compatibility

=== Implementation details

The caching mechanism stores recently calculated kerning values indexed by glyph pair identifiers.
When the `ttf_get_glyph_dsc_cb` function is called which is reponsible for getting the description of the current glyph during the rendering phase, 
we check to see if the current pair of glyphs (current glyph and next one) exist in cache and if so, we avoid calling the `stbtt_GetGlphyKernAdvance`.
If it doesn't we calculate it and store it in the cache. This will evict an entry from the cache if there's not enough space.

== Performance results

=== Quantitative improvements

Post-optimization measurements demonstrate substantial performance gains.

The application startup time saw a 660ms improvement:

```bash
hyperfine --warmup 10 "./build/bin/tiny_ttf_demo_cache --first-render-only"

Benchmark 1: ./build/bin/tiny_ttf_demo_cache --first-render-only
  Time (mean ± σ):     276.1 ms ±   9.3 ms    [User: 136.2 ms, System: 122.4 ms]
  Range (min … max):   267.4 ms … 300.4 ms    10 runs
```

The first render time dropped from ~214ms to ~9ms:

```bash
❯ ./build/bin/tiny_ttf_demo_cache
[User]	(0.265, +265)	main: Time for first render (rendering + layout) 12 ms
[User]	(0.275, +10)	main: Time for rendering only (no layout) 10 ms
❯ ./build/bin/tiny_ttf_demo_cache
[User]	(0.264, +264)	main: Time for first render (rendering + layout) 11 ms
[User]	(0.273, +9)	main: Time for rendering only (no layout) 8 ms
❯ ./build/bin/tiny_ttf_demo_cache
[User]	(0.255, +255)	main: Time for first render (rendering + layout) 12 ms
[User]	(0.264, +9)	main: Time for rendering only (no layout) 9 ms
❯ ./build/bin/tiny_ttf_demo_cache
[User]	(0.243, +243)	main: Time for first render (rendering + layout) 11 ms
[User]	(0.251, +8)	main: Time for rendering only (no layout) 8 ms
```

And when running the application we can see an average render time of ~4ms per frame vs the previous ~105ms per frame:

#figure(image("./media/perf_render_time_running_app.png", width:50%), caption: [Render time during application execution after optmization])

=== Profiling analysis

#figure(image("./media/perf_fg.png", width: 50%), caption:[Flamegraph after optmization])

The optimized flame graph reveals that `stbtt_GetGlyphKernAdvance` now represents only 0.918% of total execution time, compared to the original 50%. This reduction demonstrates successful elimination of redundant kerning calculations through effective caching.

=== Performance impact analysis

The optimization achieved exceptional improvements across all measured metrics:

- *Rendering performance*: Frame rates improved from ~4 FPS to 250 FPS, enabling smooth interactive experiences
- *Application responsiveness*: Startup time reduction makes the application practical for embedded systems with limited processing power
- *Resource efficiency*: Reduced CPU utilization allows for better multitasking and lower power consumption

== Technical implications

=== Cache effectiveness

The dramatic performance improvements indicate high cache hit rates for kerning operations, suggesting that text rendering typically involves repeated glyph pairs.
This behavior is expected in natural language text where common letter combinations appear frequently.

=== Memory overhead

In this specific case, the cache can hold up to 183 entries. Each node stores 12 bytes of data,
and there's an estimated overhead of about 32 bytes per node for maintaining internal structures—such as parent and child pointers used in the red-black tree implementation.
This results in an approximate total memory overhead of 8 KB.
Unfortunately, the node overhead is huge in this case which points to other optimization possibilities inside the LVGL's cache module.

Considering the significant performance improvements this cache provides, the memory usage represents an excellent trade-off between memory and performance.

It's also worth noting that the cache size is configurable through the standard LVGL configuration header file.
This allows users with strict memory constraints to reduce the cache size or disable it entirely.
Additionally, kerning can be completely disabled if visual appearance is not a priority.

#pagebreak()

=== Scalability considerations

The optimization scales particularly well with:
- *Complex fonts*: Fonts with extensive kerning tables benefit most from caching
- *Repeated text content*: Applications displaying similar text content see maximum performance gains
- *Long-running applications*: Cache effectiveness increases over application lifetime

== Conclusion

This optimization project demonstrates the effectiveness of targeted performance analysis using profiling tools. The flame graph analysis enabled precise identification of the performance bottleneck, leading to a focused solution that achieved remarkable improvements.

Key lessons learned:
- *Profiling first*: Performance assumptions can be misleading; data-driven analysis is essential
- *Leverage existing infrastructure*: Utilizing LVGL's existing cache system minimized implementation complexity while maximizing effectiveness
- *Measure comprehensively*: Evaluating multiple performance metrics (render time, startup time, CPU utilization) provides complete optimization validation

The 26x improvement in average render time transforms LVGL's usability for font-intensive applications, particularly in embedded systems where computational resources are constrained.
This optimization technique could be applied to other graphics libraries facing similar kerning calculation bottlenecks.
