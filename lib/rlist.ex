defmodule RList do
  @moduledoc "README.md" |> File.read!()

  @enforce_keys [ :list, :ptr ]
  defstruct [ :list, :ptr ]

  defmacro __using__(_) do
    quote do
      require RList
    end
  end

  @type t() :: %RList{}

  @doc """
  Used to match RList in the style of erlang list pattern. Ex:
  ```elixir
  defmodule Tests do
    use RList
    import RList

    def test(match [h | t]) do
      IO.puts "H: \#{h}"
      IO.inspect t, label: "T"
      :timer.sleep(1000)
      test(forward t)
    end
  end

  rl = RList.new([1,2,3])
  Tests.test(rl)
  ## Output:
  H: 1
  T: #RList[1, 2, 3]/1
  H: 2
  T: #RList[2, 3, 1]/2
  H: 3
  T: #RList[3, 1, 2]/3
  H: 1
  T: #RList[1, 2, 3]/1
  H: 2
  T: #RList[2, 3, 1]/2
  ...
  ...
  ```
  Combining `match` and `forward/1` you can go through a RList in a very similar way to how you do
  it with Erlang lists. You must not forget that, since RLists are endless, you must provide an
  exit condition when appropriate.
  """
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

  @doc false
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

  @doc """
  Create a new RList from a list or a range. The initial list/range will be the original list and
  the pointer of the RList will be initialized to 1.
  ```elixir
  iex> rl = RList.new([1, 2, 3, 4, 5])
  #RList[1, 2, 3, 4, 5]/1
  ```
  """
  @spec new(list :: list() | Range.t()) :: RList.t()
  def new(list) when is_list(list) do
    [h | t] = list
    %RList{list: [h | (t ++ [h])], ptr: 1}
  end
  def new(_a.._b//_c = range) do
    range |> Range.to_list() |> new()
  end

  @doc """
  Just an alias for `new(range)`.
  """
  @spec from_range(range :: Range.t()) :: RList.t()
  def from_range(_.._//_ = range), do: new(range)

  @doc """
  Return the size of the original list.
  """
  @spec size(rlist :: RList.t()) :: non_neg_integer()
  def size(rlist) do
    length(rlist.list) - 1
  end

  @doc """
  Return the current list as a tuple.
  """
  @spec to_tuple(rlist :: RList.t()) :: tuple()
  def to_tuple(rlist) do
    List.to_tuple(to_list(rlist))
  end

  @doc """
  Reset the pointer of the list to 1 and return the new RList. It is equivalent to call
  `ptr(rlist, 1)`.
  """
  @spec reset(rlist :: RList.t()) :: RList.t()
  def reset(rlist) do
    ptr(rlist, 1)
  end

  @doc """
  It is the same that call `Enum.take(rlist, count)`.
  """
  @spec take(rlist :: RList.t(), count :: non_neg_integer()) :: list()
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

  @doc """
  Take a RList, extract the first value of the current list and move de pointer 1 unit. Return the
  value and the new RList.
  ```elixir
  iex> rl = RList.new([1, 2, 3, 4, 5])
  #RList[1, 2, 3, 4, 5]/1

  iex> {value, rl} = RList.next(rl)
  {1, #RList[2, 3, 4, 5, 1]/2}

  iex> {value, rl} = RList.next(rl)
  {2, #RList[3, 4, 5, 1, 2]/3}
  ```
  """
  @spec next(rlist :: RList.t()) :: {term(), RList.t()}
  def next(rlist) do
    match([value | _]) = rlist
    new_rlist = forward(rlist)
    {value , new_rlist}
  end

  @doc """
  Take a RList, move de pointer count units and return the new RList.
  ```elixir
  iex> rl = RList.new([1, 2, 3, 4, 5])
  #RList[1, 2, 3, 4, 5]/1

  iex> rl = RList.forward(rl)
  #RList[2, 3, 4, 5, 1]/2

  iex> rl = RList.forward(rl, 3)
  #RList[5, 1, 2, 3, 4]/5
  ```
  """
  @spec forward(rlist :: RList.t(), count :: non_neg_integer() \\ 1) :: RList.t()
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

  @doc """
  Take a RList and return the current list (not the original list).
  """
  @spec to_list(rlist :: RList.t()) :: list()
  def to_list(rlist) do
    :lists.sublist(rlist.list, 1, size(rlist))
  end

  @doc """
  Return the current value of the pointer.
  """
  @spec ptr(rlist :: RList.t()) :: non_neg_integer()
  def ptr(rlist), do: rlist.ptr


  @doc """
  Set the current value of the pointer, adjust the list according to the pointer value and returns
  the new list.
  """
  @spec ptr(rlist :: RList.t(), ptr :: non_neg_integer()) :: RList.t()
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

  @doc """
  Compare 2 RList and return true if both original list are equals or false otherwise.
  """
  @spec equals?(left :: RList.t(), right :: RList.t()) :: boolean()
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
# defmodule Tests2 do
#   use RList

#   def test(RList.match [h | t]) do
#     IO.puts "H: #{h}"
#     IO.inspect t, label: "T"
#     :timer.sleep(1000)
#     test(RList.forward t)
#   end
# end
