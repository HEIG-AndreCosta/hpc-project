#import "@preview/typslides:1.2.3": *

// Project configuration
#show: typslides.with(
  ratio: "16-9",
  theme: "bluey",
)


#front-slide(
  title: "HPC - Open-Source Optimization",
  subtitle: "LVGL",
  authors: "André Costa & Alexandre Iorio",
)

#slide[
  == What is LVGL?
  #grid(
    columns: (1fr, 2fr),
    gutter: 20pt,
    [
      #image("./media/lvgl.png", width: 80%)
    ],
    [
      *Light and Versatile Graphics Library*
      - Open-source embedded GUI framework
      - Designed for microcontrollers and small processors
      - Minimal resource requirements
      - Rich set of widgets and animations
      - Used in IoT devices, wearables, industrial displays
    ]
  )
]

#title-slide[
  Intuition-Based Optimization
]

#slide[
  == Initial Approach: Drawing Operations
  *Assumption:* Drawing operations must be the bottleneck
  
  *Strategy:*
  - Optimize pixel-level drawing functions
  - Implement custom rendering algorithms
  - Focus on graphics pipeline efficiency
  
  *Confidence:* High - seemed logical for a graphics library
]

#slide[
  == Original drawing code - RGB565 blend operation with opa
  ```c
  for(y = 0; y < h; y++) {
      for(x = 0; x < w; x++) {
          dest_buf_u16[x] = lv_color_16_16_mix(src_buf_u16[x],
                            dest_buf_u16[x], 
                            opa);
      }
      dest_buf_u16 = drawbuf_next_row(dest_buf_u16, dest_stride);
      src_buf_u16 = drawbuf_next_row(src_buf_u16, src_stride);
  }
  ```
]
#slide[
  == Original drawing code - RGB565 blend operation with opa
  ```c
  uint16_t lv_color_16_16_mix(uint16_t c1, uint16_t c2, uint8_t mix)
  {
      if(mix == 255) return c1;
      if(mix == 0) return c2;
      if(c1 == c2) return c1;
      uint16_t ret;
      mix = (uint32_t)((uint32_t)mix + 4) >> 3;
      uint32_t bg = (uint32_t)(c2 | ((uint32_t)c2 << 16)) & 0x7E0F81F;
      uint32_t fg = (uint32_t)(c1 | ((uint32_t)c1 << 16)) & 0x7E0F81F;
      uint32_t result = ((((fg - bg) * mix) >> 5) + bg) & 0x7E0F81F;
      return (uint16_t)(result >> 16) | result;
  }
  ```
]

#slide[
  == Optimized drawing code - RGB565 blend operation with opa
  #set text(
    //font: "New Computer Modern",
    size: 15pt
  )

  ```c
      for(int32_t y = 0; y < h; y++) {
        uint16_t * dest_row      = dest_buf_u16;
        const uint16_t * src_row = (const uint16_t *)src_buf_u16;
        int32_t x                = 0;

        for(; x < w - 7; x += 8) {
            vst1q_u16(&dest_row[x], lv_color_16_16_mix_8_with_opa(&src_row[x], &dest_row[x], opa));
        }
        for(; x < w - 3; x += 4) {
            vst1_u16(&dest_row[x], lv_color_16_16_mix_4_with_opa(&src_row[x], &dest_row[x], opa));
        }
        for(; x < w - 1; x += 2) {
            *(uint32_t *)&dest_row[x] = lv_color_16_16_mix_2_with_opa(&src_row[x], &dest_row[x], opa);
        }
        for(; x < w - 0; x += 1) {
            dest_row[x] = lv_color_16_16_mix(src_row[x], dest_row[x], opa);
        }
        dest_buf_u16 = drawbuf_next_row(dest_buf_u16, dest_stride);
        src_buf_u16  = drawbuf_next_row(src_buf_u16, src_stride);
    }
  ```
]
#set page(columns: 2)
#slide[
  #set text(
    //font: "New Computer Modern",
    size: 10pt
  )
 

  == Optimized drawing code - RGB565 blend operation with opa
```c
const uint16x8_t c1_vec  = vld1q_u16(c1);
const uint16x8_t c2_vec  = vld1q_u16(c2);
const uint16x8_t mix_vec = vmovq_n_u16(opa);
const uint16x8_t mix_zero_mask = vceqq_u16(mix, vdupq_n_u16(0));
const uint16x8_t mix_full_mask = vceqq_u16(mix, vdupq_n_u16(255));
const uint16x8_t equal_mask    = vceqq_u16(c1_vec, c2_vec);

mix = vshrq_n_u16(vaddq_u16(mix, vdupq_n_u16(4)), 3);
/* Split into low and high parts for 32-bit operations */
uint32x4_t c1_low  = vmovl_u16(vget_low_u16(c1_vec));
uint32x4_t c1_high = vmovl_u16(vget_high_u16(c1_vec));
uint32x4_t c2_low  = vmovl_u16(vget_low_u16(c2_vec));
uint32x4_t c2_high = vmovl_u16(vget_high_u16(c2_vec));
uint32x4_t fg_low  = vorrq_u32(c1_low, vshlq_n_u32(c1_low, 16));
uint32x4_t fg_high = vorrq_u32(c1_high, vshlq_n_u32(c1_high, 16));
uint32x4_t bg_low  = vorrq_u32(c2_low, vshlq_n_u32(c2_low, 16));
uint32x4_t bg_high = vorrq_u32(c2_high, vshlq_n_u32(c2_high, 16));

/* Apply mask 0x7E0F81F to extract RGB components */
const uint32x4_t mask = vdupq_n_u32(0x7E0F81F);
fg_low                = vandq_u32(fg_low, mask);
fg_high               = vandq_u32(fg_high, mask);
bg_low                = vandq_u32(bg_low, mask);
bg_high               = vandq_u32(bg_high, mask);

const uint32x4_t mix_low  = vmovl_u16(vget_low_u16(mix));
const uint32x4_t mix_high = vmovl_u16(vget_high_u16(mix));
```
#colbreak()
```c
/* Perform the blend: ((fg - bg) * mix) >> 5 + bg */
const uint32x4_t diff_low     = vsubq_u32(fg_low, bg_low);
const uint32x4_t diff_high    = vsubq_u32(fg_high, bg_high);
const uint32x4_t scaled_low   = vmulq_u32(diff_low, mix_low);
const uint32x4_t scaled_high  = vmulq_u32(diff_high, mix_high);
const uint32x4_t shifted_low  = vshrq_n_u32(scaled_low, 5);
const uint32x4_t shifted_high = vshrq_n_u32(scaled_high, 5);
uint32x4_t result_low         = vaddq_u32(shifted_low, bg_low);
uint32x4_t result_high        = vaddq_u32(shifted_high, bg_high);

/* Apply final mask */
result_low  = vandq_u32(result_low, mask);
result_high = vandq_u32(result_high, mask);

/* Convert back to 16-bit: (result >> 16) | result */
const uint32x4_t final_low  = vorrq_u32(result_low, vshrq_n_u32(result_low, 16));
const uint32x4_t final_high = vorrq_u32(result_high, vshrq_n_u32(result_high, 16));

const uint16x4_t packed_low  = vmovn_u32(final_low);
const uint16x4_t packed_high = vmovn_u32(final_high);
uint16x8_t result            = vcombine_u16(packed_low, packed_high);

result = vbslq_u16(mix_zero_mask, c2_vec, result);
result = vbslq_u16(mix_full_mask, c1_vec, result);
result = vbslq_u16(equal_mask, c1_vec, result);

return result;
```
]

#set page(columns: 1)
#set text(
  size: 20pt
)

#slide[
  == Results
  #figure(image("./media/results-neon.png"))
  #set align(center)
  *Spot the difference!* \
  #text(size:10pt)[Good luck]
]

#slide[
  == The worst part ?
  #figure(image("./media/diff-stat.png"))
]

#title-slide[
  What did we learn today ?
]

#set align(center)
#slide[
  #text(size:40pt)[*Always profile first!*]
]
#set align(left)

#title-slide[
  Let's try again
]

#slide[
  == Font Rendering Performance

  *An actual issue discovered:*
  - Instead of optimizing just for the sake of it,
  - Text rendering extremely slow (4 FPS) 
    - (\~214ms render time) 
    - On our machine !
]

#slide[
  == New Methodology: Profile First
  
  *Step 1:* Measure actual performance bottlenecks
  
  *Step 2:* Use profiling tools to identify hotspots
  
  *Step 3:* Target optimization based on data
  
  *Step 4:* Verify improvements with measurements
]

#title-slide[
  Font Rendering Background
]

#slide[
  == TrueType
  - Is an outline font standard
  - Developed by Apple in the late 1980s
  - Offers font developers high degree of control
  - Stores information about a particular font including:
    - Glyph shapes and outlines
    - Spacing and kerning data
    - Font metrics and metadata
]

#title-slide[
  Terminology
]

#slide[
  == Font
  - A set of printable or displayable text characters
  - Defined by common characteristics:
    - Size (point size)
    - Style (bold, italic, regular)
    - Typeface family (Arial, Times, etc.)
  - Contains all glyphs for a character set
]

#slide[
  == Glyph
  - Individual character or symbol representation
  - Visual form of a character in a specific font
  - Examples: "A", "a", "1", "!", "\@"
  - Each glyph has unique metrics and shape data
]

#slide[
  == Kerning
  - Adjustment of spacing between specific character pairs
  - Improves visual appearance and readability
  - Examples:
    - "AV" - letters moved closer together
    - "To" - 'o' tucked under 'T' overhang
  - Critical for professional typography
]


#title-slide[
  Performance Analysis
]

#slide[
  == Initial Performance Issues
  - First render time: ~214ms
  - Application startup: ~937ms  
  - Frame rate: 4 FPS
  - Unacceptable user experience for interactive applications
]


#slide[
  === Profiling Results - Original
  #figure(image("./media/original_fg.png", width: 50%))
  - `stbtt_GetGlyphKernAdvance` consumed 50% of CPU cycles
  - Kerning calculations repeated for same glyph pairs
]


#title-slide[
  Optimization Strategy
]

#slide[
  == Root Cause Analysis
  - LVGL already cached fonts and glyphs effectively
  - Kerning calculations performed on-demand every time
  - No caching for expensive kerning operations
  - Same glyph pairs recalculated repeatedly
]

#slide[
  == Solution: Kerning Cache
  - Leverage LVGL's existing red-black tree cache infrastructure
  - Cache recently calculated kerning values
  - Index by glyph pair identifiers
  - Minimal code changes for maximum impact
  #figure(image("./media/diff-stat-ttf.png", width: 50%))
]

#title-slide[
  Results
]

#slide[
  == Performance Improvements
  - First render time: 214ms -> 9ms (24x faster)
  - Application startup: 937ms -> 276ms (3.4x faster)
  - Frame rate: 4 FPS -> 250 FPS (26x faster)
  - Memory overhead: ~8KB (acceptable trade-off)
]

#slide[
  == Profiling Results - Optimized
  #figure(image("./media/perf_fg.png", width: 50%))
  - `stbtt_GetGlyphKernAdvance` now only 0.918% of execution time
  - 50% -> 0.918% cycles
]

#slide[
  == Running Application Comparison
 
  #grid(
    columns: 2,
    gutter: 20pt,
    [
      *Before Optimization*
      #image("./media/original_render_time_running_app.png", width: 90%)
      Average: ~105ms per frame
    ],
    [
      *After Optimization*  
      #image("./media/perf_render_time_running_app.png", width: 90%)
      Average: ~4ms per frame
    ]
  )
]

#title-slide[
  Methodology Comparison
]

#slide[
  == Two Approaches Compared

  #grid(
    columns: 2,
    gutter: 20pt,
    [
      *Intuition-Based*
      - 2000+ lines of code
      - 1 week of development
      - 0% performance improvement
      - Wasted effort
    ],
    [
      *Data-Driven*
      - 130 lines of code
      - 2 hours of development  
      - 2400% performance improvement
      - Targeted solution
    ]
  )
  
  #text(size: 20pt, fill: blue)[
    *Key Takeaway:* Profiling saves time and delivers results
  ]
]

#title-slide[
  Live demo
]

#focus-slide[
  Questions ?
]
