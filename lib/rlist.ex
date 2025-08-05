defmodule RList do
  defstruct [ :list, :ptr ]

  defmacro __using__(_) do
    quote do
      require RList
      import RList
    end
  end

  ## When it is a pattern
  defmacro match([{:|, _, [h, t]}]) do
    # IO.inspect list
    # [{:|, _, [h, t]}] = list
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

  def reduce(rlist, {:cont, [{[], count}]} = acc, fun) do
    rlist |>  RList.take(count) |> Enumerable.reduce(acc, fun)
  end
  def reduce(rlist, acc, fun) do
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

  def test(match [h | t]) do
    IO.puts "H: #{h}"
    IO.inspect t, label: "T"
    :timer.sleep(1000)
    test(forward t)
  end
end
