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

## 04

### Task 1
- honestly took me a while to find the correct functions for the simple case (std.mem.count)
- reversing the word was also unexpectedly hard, did not find a way to copy and reverse in one step
- while counting the vertical occurences i noticed that the input is always square (same amount of rows and columns)
- diagonal counting was a bit tricky, after some trial and error i got it working
- to avoid the pain of writing more diagonal counting logic, i had the idea the reverse the order of the lines in the input
and pass it to the diagonal counting function again
- diagonal logic is skipping rows / columns if the diagonal is too short to contain the word, proud of that one

### Task 2
- had the idea to collect all middle indices of matches in a list, then check for duplicates, each duplicate is a valid match
- basically had to replace all std.mem.count calls with std.mem.indexOfPos loop
- somehow didnt realize that i only needed to do this for diagonal search and wasted some time
- the index calculation of the diagonal match was also painful, especially when the input is reversed
- probably need to visualize the data for the next problems
- idx calculation in first and second task is bad and felt more like guessing than calculating

## 05

### Task 1
- i had the idea to use a HashMap where i can look up all numbers that should appear before a specific number (number -> arraylist of numbers)
- print queues are just an arraylist of slices
- with these data structures in place, the actual logic was not that hard:
	1) iterate over all print_queues
	2) iterate in one print_queue
	3) check if the dependencies of the current number appear after the current index (if yes -> current print queue is invalid)
- i managed to eliminate the dependants loop by using indexOfAny instead of iterating and using indexOfScalar when checking the dependants
- had to free the Slices in the ArrayList and the ArrayLists in the HashMap at the end of the function, slowly getting the hang of it

### Task 2
- saved indices of invalid print queues in an ArrayList
- wrote a sort compare function which takes the number_to_dependants HashMap as context
- iterate over invalid print queues, sort them with my compare function, add middle element to result
- all in all this felt like a very clean solution, i think my choice of data structures helped a lot

## 06

### Task 1
- pretty straightforward, used enums and structs to keep the state
- struct with functions for the guard actions (next, previous, turn) which change the passed in variables (pointers)
- extensively used switch expressions for handling the different directions, this is amazing

### Task 2
- improved the struct usage of Task 1, the guard struct now has all state and methods dont need any arguments anymore (next, previous, turn)
- solution was very brute forcy, but i could not think of a better way
- created a list of every possible additional obstacle position (no obstacle placed and not the starting point of the guard)
- the core algorithm now has a turn log which keeps all turn entries (row, col, direction)
- we check the turn log for every new turn, if the current turn is already in the log, we found a loop
- managed to optimize by only trying the additional obstacle positions which are in the initial path of the guard,
because other obstacles will not change the outcome (2s -> 0.5s runtime)

## 07

### Task 1
- most difficult for me was the operand permutation function with the associated memory management of arraylists and slices
- basic data structures: calculations as HashMap of result to slice of values
- precalculate all needed permutations  into a HashMap of the permutation_len to slices of slices of Operands (u64 -> []const []const Operand)
- for each calculation, loop over permutations, early exit of result is higher than expected, exit after permutation calc if result is equal to expected

### Task 2
- added Operand.Concat enum value
- permutation function now iterates over possible enum values
- we concat the numbers by: a * pow(10, digits_of(b)) + b,
e.g. a = 10, b = 20 => 10 * (10^2) + 20 => 1000 + 20 = 1020
- i hope my math on concat is faster then converting to string and back
- runtime is now quite slow: 4.5s, but i am happy with the solution (first part was less than 100ms)
- could probably filter permutations before calculation depending on the numbers and result,
most permutations with a lot of concats are invalid because they get big very fast
- in hindsight realized that my hashmap of results to values would not work if a there are multiple entries for one result,
this case was not covered in the provided data

## 08

### Task 1
- while parsing the data created a hashmap of antenna char to antenna position list (in input string)
- antinode positions are saved in std.AutoHashMap(u64, void) because we only need to know if a position is an antinode
- the core logic iterates over each antenna type, in each antenna type iterate over every position combination
- realization: position of antinodes in the input string are just addition (antenna b) or substraction (antenna a) of the delta of the antenna positions
- still need to check for valid antinode positions, could be out of bounds (index exists, but not in the grid) -> used column difference of antenna positions
- definitely went smoother than the last grid based tasks

### Task 2
- had to use a while loop for the antinode calculations, as long as either a next antinode or a previous antinode exist
- then calculate the antinode position and validate it (depending on current iteration of while loop)
- also add every antenna position to the antinode positions hashmap, we skip iterations for less than one antenna anyway
- overall very happy, performance is also good (both tasks ~20ms each)

## 09

### Task 1
- this part was not that easy, but i managed to do it with a loop which:
	- calculates checksum for file
	- fills next empty space with (potentially partial) file(s) (starting at the end of the file list)
	- exit condition is when reverse index and index on file list are equal


### Task 2
- struggled a little bit, chose to do it with a tagged union list which was either file or empty
- was not that happy with the performance in the end, so optimized it:
	- tagged union -> File and Empty arraylists
	- only calculate checksum once, when we positioned the block
	- use arithmetic progression formula to calculate sum of range (checksum)

## 10

### Task 1

- quickly reached for recursive function which calculates the next position of the trailhead
- didnt understand why my results were wrong, turns out we need to deduplicate ending positions
- used AutoHashMap pointer and just added the count for each trailhead to the result

### Task 2

- basically did this when starting with the first task, just had to use the code i had before
- this went very smooth

## 11

### Task 1

- one shotted this, but solution is not that fast (~1.2s)

### Task 2

- ...probably have to do this in a smarter way or it will never complete
- at first i tried to optimize the blinking , e.g. skipping blinks
	- if digits of number are 2^n, there is way to split multiple times in one step, but this is only applicable if one part is not zero
	- in the end, this was way too complicated
- after optimizing failed, i tried to cache the results of each blinking step, which was not possible with the structure i used before
- in the end i managed to cache the results in a HashMap of struct{ number, blinks } to result (number of stones), HashMap needed a custom context with hash and eql functions
- blinking function is now called recursively for each blinking step, if the result is already in the cache, return it
- this was way faster than expected (15ms), very happy with this solution
- just used one solution.zig file for both tasks & tests, the unoptimized version of task 1 is still in the git history


## 12

### Task 1
- my initial approach worked pretty well, i was iterating over the one dimensional input and looking for an existing area of that
char above and to the left
- had to merge areas if a char has different areas with the same char above and to the left

### Task 2
- this was more tricky, i did the following for each area
	- store fence sides of each plot
	- group plots by row/col for all fence sides separately (top, left, right, bottom)
	- calculate side count for each side type (top, left, right, bottom) by sorting the Plots by idx and checking if the idx is continous
- overall happy with my solution, managed to find grid related bugs in a previous solution (day 10)
