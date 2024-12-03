# Advent of Code 2024

- i am using AoC to learn Zig basics
- this was helpful to get started: https://kristoff.it/blog/advent-of-code-zig/

# Notes

## 01
- went pretty good, added tests with testing allocator after submitting

## 02
- solution_1 went well, submitted too low number on solution_2 at first
- found out that zig for with range syntax is excluding the end,  
so my loop had to be `for (0..numbers.items.len - 1)` instead of `for (0..numbers.items.len - 2)`
- looked up edgecase data on reddit to fix solution_2 (input_edgecase.txt)
- found out about the order edgecase which i missed
- looked at other solutions after, could have used a window function (std.mem.window)
- creating many ArrayLists could probably get optimized?
