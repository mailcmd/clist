defmodule RList do
  @doc """
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

  It is necessary to clarify what the pointer value means. When the pointer is, for example, 2, it
  means that the first value in the current list is equivalent to the value with index 2 in the
  original list (remember, indexes in RList work on a base 1).

  ```elixir
  ## When pointer is 1 you see the original list
  #RList[1, 2, 3, 4, 5]/1
            ^
            |
            ·----------------------------------------------·
                                                           |
  ## When pointer is not 1 you see the list rotatated      |
  #RList[2, 3, 4, 5, 1]/2                                  |
                        |                                  |
                        ·----------------------------------·

  ```

  ## Enumerable

  RList implements Enumerable so you can play with them as Streams or use the Enum.* functions.

  ```elixir
  iex> rl = RList.new([1, 2, 3, 4, 5])
  #RList[1, 2, 3, 4, 5]/1

  iex> Enum.take(rl, 20)
  [1, 2, 3, 4, 5, 1, 2, 3, 4, 5, 1, 2, 3, 4, 5, 1, 2, 3, 4, 5]
  ```


  """
  @enforce_keys [ :list, :ptr ]
  defstruct [ :list, :ptr ]

  defmacro __using__(_) do
    quote do
      require RList
    end
  end

  ## When it is a pattern
  defmacro match([{:|, _, [h, t]}]) do
    {:=, [],
    [
      {:%, [],
       [
         {:__aliases__, [alias: false], [:RList]},
         {:%{}, [],
          [
            list: [
              {:|, [],
               [
                 h,
                 {:_, [], Elixir}
               ]}
            ]
          ]}
       ]},
      t
    ]}
  end
  defmacro match(list), do: list

  defmacro from_list(list) do
    quote do
      [h | t] = unquote(list)
      %RList{list: [h | (t ++ [h])], ptr: 1}
    end
  end

  @doc false
  defmacro oo(list) do
    case __CALLER__.context do
      :match -> match(list)
      nil when is_list(list) -> quote do: from_list(unquote(list))
    end
  end

  #################################################################################################
  ## API
  #################################################################################################

  def new(list) when is_list(list) do
    [h | t] = list
    %RList{list: [h | (t ++ [h])], ptr: 1}
  end
  def new(_a.._b//_c = range) do
    range |> Range.to_list() |> new()
  end

  def from_range(_.._//_ = range), do: new(range)

  def size(rlist) do
    length(rlist.list) - 1
  end

  def to_tuple(rlist) do
    List.to_tuple(to_list(rlist))
  end

  def reset(rlist) do
    ptr(rlist, 1)
  end

  def take(_, 0), do: []
  def take(%RList{} = rlist, count) do
    {value, rlist} = next(rlist)
    [ value ] ++ take(rlist, count - 1)
  end
  def take(%Stream{} = stream, count) do
    rlist = stream.enum
    {value, rlist} = next(rlist)
    [ value ] ++ take(%Stream{stream | enum: rlist}, count - 1)
  end

  def next(rlist) do
    match([value | _]) = rlist
    new_rlist = forward(rlist)
    {value , new_rlist}
  end

  def forward(rlist, count \\ 1)
  def forward(rlist, 0), do: rlist
  def forward(rlist, count) do
    len = size(rlist)
    %RList{list: [_ | [h | t]], ptr: ptr} = rlist
    ptr = ptr == len && 1 || (ptr + 1)
    %RList{list: [h | (t ++ [h])], ptr: ptr} |> forward(count - 1)
  end
  # Just for backward compatibility
  # TODO: remove from the next version
  @doc false
  def rotate(rlist), do: forward(rlist)

  def to_list(rlist) do
    :lists.sublist(rlist.list, 1, size(rlist))
  end

  def ptr(rlist), do: rlist.ptr
  def ptr(%RList{list: list} = rlist, new_ptr) when is_integer(new_ptr) and new_ptr > 0 and new_ptr < length(list) do
    ptr_helper(rlist, new_ptr)
  end
  defp ptr_helper(%RList{ptr: ptr} = rlist, new_ptr) when new_ptr == ptr, do: rlist
  defp ptr_helper(%RList{ptr: ptr} = rlist, new_ptr) when new_ptr > ptr do
    off = new_ptr - ptr + 1
    %RList{rlist |
      list:
        :lists.sublist(rlist.list, off, size(rlist)-off+1)
        ++
        :lists.sublist(rlist.list, 1, off),
      ptr: new_ptr
    }
  end
  defp ptr_helper(%RList{ptr: ptr} = rlist, new_ptr) when new_ptr < ptr do
    len = size(rlist)
    off =  len - (ptr - new_ptr) + 1
    %RList{rlist |
      list:
        :lists.sublist(rlist.list, off, size(rlist)-off+1)
        ++
        :lists.sublist(rlist.list, 1, off),
      ptr: new_ptr
    }
  end

  def equals?(left, right) do
    left |> RList.ptr(1) |> Map.get(:list) == right |> RList.ptr(1) |> Map.get(:list)
  end

end

#################################################################################################
## Protocols implementations
#################################################################################################
defimpl Inspect, for: RList do
  import Inspect.Algebra
  def inspect(rlist, opts) do
    concat(["#RList", to_doc( RList.to_list(rlist), opts), "/#{rlist.ptr}"])
  end
end

defimpl String.Chars, for: RList do
  def to_string(rlist) do
    rlist |> RList.to_list() |> String.Chars.to_string()
  end
end

defimpl Enumerable, for: RList do
  def count(rlist) do
    rlist |> RList.to_list() |> Enumerable.count()
  end

  def member?(rlist, value) do
    {:ok, rlist |> RList.to_list() |> Enum.member?(value)}
  end

  # For Streams
  def reduce(rlist, {:cont, [{[], count}]} = acc, fun) do
    rlist |>  RList.take(count) |> Enumerable.reduce(acc, fun)
  end
  # For RLists
  def reduce(rlist, {:cont, {[], count}} = acc, fun) do
    rlist |>  RList.take(count) |> Enumerable.reduce(acc, fun)
  end
  # Fallback trait RList as a common list
  def reduce(rlist, acc, fun) do
    # IO.inspect {rlist, acc, fun}
    rlist |>  RList.to_list() |> Enumerable.reduce(acc, fun)
  end

  def slice(rlist) do
    fun = &slicing_fun(rlist, &1, &2, &3)
    {:ok, 9_999_999, fun}
  end

  defp slicing_fun(rlist, start, amount, _step) do
    rlist |> RList.ptr(start+1) |> RList.take(amount)
  end
end


#################################################################################################
defmodule Tests2 do
  use RList

  def test(RList.match [h | t]) do
    IO.puts "H: #{h}"
    IO.inspect t, label: "T"
    :timer.sleep(1000)
    test(RList.forward t)
  end
end
