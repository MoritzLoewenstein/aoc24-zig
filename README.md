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
