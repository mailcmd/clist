# Circular Lists (CList Module)

`CList` allow to work with circular lists. A circular lists is a finite list that can be traversed
as if it were infinite. This is possible because in a circular list, when you reach the end of the 
list, you go back to the beginning and take the first element of the list as if it were next to 
the last one. In other words, we could assume that a copy of the original list is inserted at the 
end of the list, and so on ad infinitum.

Internally a `CList` is a map that store the *original list* (see below ()[original and current list]) 
and a pointer indicating the current position in base 1 (as Erlang lists).

Although internally a `CList` is a map, its visual representation (IO.inspect) is:

```elixir
iex> CList.new([1, 2, 3, 4, 5])
#CList[1, 2, 3, 4, 5]/1
```
As you can see a list and a pointer will always be displayed. If you move the pointer the representation
will look different, but internally the *original list* will be the same.

```elixir
iex> a = CList.new([1, 2, 3, 4, 5])
#CList[1, 2, 3, 4, 5]/1

iex> b = CList.forward(a)
#CList[2, 3, 4, 5, 1]/2

iex> CList.equals?(a, b)
true
```
In the case of `a` and `b` both, the list and the pointer, differ, but the `CList`s are equals 
because their sequential lists are the same.

And talking about the concept of `equal` on `CList`s, it is important to note that 2 `CList`s are 
considered equal if they have the same size and their traversal sequence is exactly the same.

```elixir
iex> a = CList.new [1, 2, 3, 4, 5, 6]
#CList[1, 2, 3, 4, 5, 6]/1

iex> b = CList.new [5, 6, 1, 2, 3, 4]
#CList[5, 6, 1, 2, 3, 4]/1

iex> CList.equals?(a, b)
true

iex> b = CList.new [6, 5, 1, 2, 3, 4]
#CList[6, 5, 1, 2, 3, 4]/1

iex> CList.equals?(a, b)
false
```

## Original and current list

What `CList` stores at all times is what we call the *current list* (i.e., the rotated list) but 
implicitly also store what we will call the *original list*, which is the *current list* when the 
pointer is equal to 1.

```elixir 
iex> a = CList.new([:a, :b, :c, :d, :e])
#CList[:a, :b, :c, :d, :e]/1 
## Original list: [:a, :b, :c, :d, :e]
## Current list: [:a, :b, :c, :d, :e]

iex> CList.forward(a, 3)
#CList[:d, :e, :a, :b, :c]/4
## Original list: [:a, :b, :c, :d, :e]
## Current list: [:d, :e, :a, :b, :c]

```
## The pointer

Now is time to explain what the pointer value means. When the pointer is, for example, 2, it
means that the first value in the *current list* is equivalent to the value with index 2 in the 
*original list* (remember, indexes in `CList` work on a base 1).

```elixir
## When pointer is 1, you see the original list
#CList[1, 2, 3, 4, 5]/1
          ^
          |
          +----------------------------------------------+
                                                         |
## When pointer is not 1, you see the list rotatated     |
#CList[2, 3, 4, 5, 1]/2                                  |
                      |                                  |
                      +----------------------------------+

```

## Enumerable

`CList` implements `Enumerable`, so you can play with `Streams` or use `Enum.*` functions.

```elixir
iex> a = CList.new([1, 2, 3, 4, 5])
#CList[1, 2, 3, 4, 5]/1

iex> Enum.take(a, 20)
[1, 2, 3, 4, 5, 1, 2, 3, 4, 5, 1, 2, 3, 4, 5, 1, 2, 3, 4, 5]

iex> a 
  |> Stream.map(fn v -> v * 3 end) 
  |> Stream.map(fn v -> v - 1 end) 
  |> Enum.take(22)
[2, 5, 8, 11, 14, 2, 5, 8, 11, 14, 2, 5, 8, 11, 14, 2, 5, 8, 11, 14, 2, 5]
```

Since a `CList` could be iterated ad infinitum, the `Enum.*` functions that has not stop condition 
will take the *current list* of the `CList` as enumerable input. 

```elixir
iex> a = CList.new([1, 2, 3, 4, 5])
#CList[1, 2, 3, 4, 5]/1

iex> Enum.map(a, fn v -> v * 2 end)
[2, 4, 6, 8, 10]

iex> rl = CList.forward(a, 3)
#CList[4, 5, 1, 2, 3]/4

iex> Enum.map(a, fn v -> v * 2 end)
[8, 10, 2, 4, 6]
```

## TODO
                      
One million tests `¯\_(ツ)_/¯`

## How to use

```elixir
defmodule TestCList do
  use CList

  def hello do
    ["h", "e", "l", "l", "o", " ", "w", "o", "r", "l", "d", "! "]
      |> CList.new()
      |> say_hello_but_in_a_cool_way()
  end

  def say_hello_but_in_a_cool_way(cl, count \\ 5)
  def say_hello_but_in_a_cool_way(_, 0), do: IO.write("\n")
  def say_hello_but_in_a_cool_way(CList.match([c | l]), count) do
    IO.write(c)
    :timer.sleep(200)
    say_hello_but_in_a_cool_way(CList.forward(l), count - (c == "! " && 1 || 0))
  end
end
```

You may also want to import `match/1` and `forward/1` to avoid having to explicitly specify 
`CList`...

```elixir
defmodule TestCList do
  use CList
  import CList, only: [match: 1, forward: 1]
  ...

  def say_hello_but_in_a_cool_way( match([c | l]), count) do
    IO.write(c)
    :timer.sleep(200)
    say_hello_but_in_a_cool_way( forward(l), count - (c == "! " && 1 || 0))
  end

  ...
end
```


## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `clist` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:clist, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/clist>.

