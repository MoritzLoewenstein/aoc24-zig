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

## 03

### Task 1
- finding the mul statements with a regex would be trivial, but i wanted to intentionally avoid regex (`/mul\(\d{1,3},\d{1,3}\)/`)
- used a basic state machine which progresses one char at a time
- used switch expression with State enum which evaluates to next state
- zig switch expressions forced me to handle every enum value
- each prong of this expression is also either a switch expression or
a labeled block which returns the new State via a labeled break statement
- basic idea: outer switch handles separates the logic by state,
the inner switch blocks handles the state transition logic for one specific state depending on the current char
- there is a tmp slice which is cleared if state is initial state again

### Task 2
- first thought about rewriting the state machine, consuming more than one char in one State transition
- instead wrote a function which removes every range of invalid instructions starting with don't() and ending with do()
- learned more about memory management in Zig, at first i just returned the slice of the arraylist (`arr_list.items`),
but because the arraylist will deinit at the end of the function (because of the defer statement),
this resulted in a segfault when accessing the return value in the caller.
- instead i needed to return `arr_list.toOwnedSlice()` and call `defer allocator.free(slice)` in the caller.
- logic wise `remove_disabled_instructions` was relatively easy, for calculating the multiplications i just
passed the result of this function into the parser created in the first task
