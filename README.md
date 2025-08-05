# RList

RList (Rotating List) allow to work with circular lists. A circular lists is a finite list that
can be traversed as if it were infinite. This is possible because in a circular list, it is
assumed that a copy of the original list is inserted at the end of the list, and so on infinitely.

Internally a RList is a map that store the original list and a pointer indicating the current
position in base 1 (as Erlang lists).

Although internally an RList is a map, its visual representation (IO.inspect) is:

```elixir
iex> RList.new([1, 2, 3, 4, 5])
#RList[1, 2, 3, 4, 5]/1
```
The original list and pointer will always be displayed. If you move the pointer the representation
look different but internally the original list will be mantained.

```elixir
iex> rl = RList.new([1, 2, 3, 4, 5])
#RList[1, 2, 3, 4, 5]/1

iex> rl2 = RList.forward(rl)
#RList[2, 3, 4, 5, 1]/2

iex> RList.equals?(rl, rl2)
true
```
As you can see, both the list and the pointer differ, but the RLists are equals because their
original lists are the same.

It is important to clarify what the pointer value means. When the pointer is, for example, 2, it
means that the first value in the current list is equivalent to the value with index 2 in the
original list (remember, indexes in RList work on a base 1).

```elixir
## When pointer is 1, you see the original list
#RList[1, 2, 3, 4, 5]/1
          ^
          |
          +----------------------------------------------+
                                                          |
## When pointer is not 1, you see the list rotatated      |
#RList[2, 3, 4, 5, 1]/2                                  |
                      |                                  |
                      +----------------------------------+

```

An RList physically stores what we will call the “current list” (i.e., the rotated list) and implicitly 
what we will call the “original list,” which is the “current list” when the pointer is equal to 1.

```elixir 
iex> rl = RList.new([1, 2, 3, 4, 5])
#RList[1, 2, 3, 4, 5]/1 
## Original list: [1, 2, 3, 4, 5]
## Current list: [1, 2, 3, 4, 5]

iex> RList.forward(rl, 3)
#RList[4, 5, 1, 2, 3]/4
## Original list: [1, 2, 3, 4, 5]
## Current list: [4, 5, 1, 2, 3]

```

## Enumerable

RList implements Enumerable so you can play with Streams or use the Enum.* functions.

```elixir
iex> rl = RList.new([1, 2, 3, 4, 5])
#RList[1, 2, 3, 4, 5]/1

iex> Enum.take(rl, 20)
[1, 2, 3, 4, 5, 1, 2, 3, 4, 5, 1, 2, 3, 4, 5, 1, 2, 3, 4, 5]

iex> rl 
  |> Stream.map(fn v -> v * 3 end) 
  |> Stream.map(fn v -> v - 1 end) 
  |> Enum.take(22)
[2, 5, 8, 11, 14, 2, 5, 8, 11, 14, 2, 5, 8, 11, 14, 2, 5, 8, 11, 14, 2, 5]
```

Since an RList could be iterated ad infinitum, the Enum.* functions that has not stop condition will 
take the current list of the RList as enumerable input. 

```elixir
iex> rl = RList.new([1, 2, 3, 4, 5])
#RList[1, 2, 3, 4, 5]/1

iex> Enum.map(rl, fn v -> v * 2 end)
[2, 4, 6, 8, 10]

iex> rl = RList.forward(rl, 3)
#RList[4, 5, 1, 2, 3]/4

iex> Enum.map(rl, fn v -> v * 2 end)
[8, 10, 2, 4, 6]

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `rlist` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:rlist, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/s8list>.

