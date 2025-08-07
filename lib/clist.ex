defmodule CList do
  @moduledoc File.read!("README.md")

  @enforce_keys [ :list, :ptr ]
  defstruct [ :list, :ptr ]

  defmacro __using__(_) do
    quote do
      require CList
    end
  end

  @type t() :: %CList{}

  @doc """
  Used to match `CList` in the style of erlang list pattern. Ex:
  ```elixir
  defmodule Tests do
    use CList
    import CList

    def test(match [h | t]) do
      IO.puts "H: \#{h}"
      IO.inspect t, label: "T"
      :timer.sleep(1000)
      test(forward t)
    end
  end

  rl = CList.new([1,2,3])
  Tests.test(rl)
  ## Output:
  H: 1
  T: #CList[1, 2, 3]/1
  H: 2
  T: #CList[2, 3, 1]/2
  H: 3
  T: #CList[3, 1, 2]/3
  H: 1
  T: #CList[1, 2, 3]/1
  H: 2
  T: #CList[2, 3, 1]/2
  ...
  ...
  ```
  Combining `match` and `forward/1` you can go through a `CList` in a very similar way to how you do
  it with Erlang lists. You must not forget that, since `CList`s are endless, you must provide an
  exit condition when appropriate.
  """
  defmacro match([{:|, _, [h, t]}]) do
    {:=, [],
    [
      {:%, [],
       [
         {:__aliases__, [alias: false], [:CList]},
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
      %CList{list: [h | (t ++ [h])], ptr: 1}
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
  Create a new `CList` from a list or a range. The initial list/range will be the original list and
  the pointer of the `CList` will be initialized to 1.
  ```elixir
  iex> rl = CList.new([1, 2, 3, 4, 5])
  #CList[1, 2, 3, 4, 5]/1
  ```
  """
  @spec new(list :: list() | Range.t()) :: CList.t()
  def new(list) when is_list(list) do
    [h | t] = list
    %CList{list: [h | (t ++ [h])], ptr: 1}
  end
  def new(_a.._b//_c = range) do
    range |> Range.to_list() |> new()
  end

  @doc """
  Just an alias for `new(range)`.
  """
  @spec from_range(range :: Range.t()) :: CList.t()
  def from_range(_.._//_ = range), do: new(range)

  @doc """
  Return the size of the original list.
  """
  @spec size(clist :: CList.t()) :: non_neg_integer()
  def size(clist) do
    length(clist.list) - 1
  end

  @doc """
  Return the current list as a tuple.
  """
  @spec to_tuple(clist :: CList.t()) :: tuple()
  def to_tuple(clist) do
    List.to_tuple(to_list(clist))
  end

  @doc """
  Reset the pointer of the list to 1 and return the new `CList`. It is equivalent to call
  `ptr(rlist, 1)`.
  """
  @spec reset(clist :: CList.t()) :: CList.t()
  def reset(clist) do
    ptr(clist, 1)
  end

  @doc """
  It is the same that call `Enum.take(rlist, count)`.
  """
  @spec take(clist :: CList.t(), count :: non_neg_integer()) :: list()
  def take(_, 0), do: []
  def take(%CList{} = clist, count) do
    {value, clist} = next(clist)
    [ value ] ++ take(clist, count - 1)
  end
  def take(%Stream{} = stream, count) do
    clist = stream.enum
    {value, clist} = next(clist)
    [ value ] ++ take(%Stream{stream | enum: clist}, count - 1)
  end

  @doc """
  Take a `CList`, extract the first value of the current list and move de pointer 1 unit. Return the
  value and the new `CList`.
  ```elixir
  iex> rl = CList.new([1, 2, 3, 4, 5])
  #CList[1, 2, 3, 4, 5]/1

  iex> {value, rl} = CList.next(rl)
  {1, #CList[2, 3, 4, 5, 1]/2}

  iex> {value, rl} = CList.next(rl)
  {2, #CList[3, 4, 5, 1, 2]/3}
  ```
  """
  @spec next(clist :: CList.t()) :: {term(), CList.t()}
  def next(clist) do
    match([value | _]) = clist
    new_clist = forward(clist)
    {value , new_clist}
  end

  @doc """
  Take a `CList`, move de pointer count units and return the new `CList`.
  ```elixir
  iex> rl = CList.new([1, 2, 3, 4, 5])
  #CList[1, 2, 3, 4, 5]/1

  iex> rl = CList.forward(rl)
  #CList[2, 3, 4, 5, 1]/2

  iex> rl = CList.forward(rl, 3)
  #CList[5, 1, 2, 3, 4]/5
  ```
  """
  @spec forward(clist :: CList.t(), count :: non_neg_integer()) :: CList.t()
  def forward(clist, count \\ 1)
  def forward(clist, 0), do: clist
  def forward(clist, count) do
    len = size(clist)
    %CList{list: [_ | [h | t]], ptr: ptr} = clist
    ptr = ptr == len && 1 || (ptr + 1)
    %CList{list: [h | (t ++ [h])], ptr: ptr} |> forward(count - 1)
  end
  # Just for backward compatibility
  # TODO: remove from the next version
  @doc false
  def rotate(clist), do: forward(clist)

  @doc """
  Take a `CList` and return the current list (not the original list).
  """
  @spec to_list(clist :: CList.t()) :: list()
  def to_list(clist) do
    :lists.sublist(clist.list, 1, size(clist))
  end

  @doc """
  Return the current value of the pointer.
  """
  @spec ptr(clist :: CList.t()) :: non_neg_integer()
  def ptr(clist), do: clist.ptr


  @doc """
  Set the current value of the pointer, adjust the list according to the pointer value and returns
  the new list.
  """
  @spec ptr(clist :: CList.t(), ptr :: non_neg_integer()) :: CList.t()
  def ptr(%CList{list: list} = clist, new_ptr) when is_integer(new_ptr) and new_ptr > 0 and new_ptr < length(list) do
    ptr_helper(clist, new_ptr)
  end
  defp ptr_helper(%CList{ptr: ptr} = clist, new_ptr) when new_ptr == ptr, do: clist
  defp ptr_helper(%CList{ptr: ptr} = clist, new_ptr) when new_ptr > ptr do
    off = new_ptr - ptr + 1
    %CList{clist |
      list:
        :lists.sublist(clist.list, off, size(clist)-off+1)
        ++
        :lists.sublist(clist.list, 1, off),
      ptr: new_ptr
    }
  end
  defp ptr_helper(%CList{ptr: ptr} = clist, new_ptr) when new_ptr < ptr do
    len = size(clist)
    off =  len - (ptr - new_ptr) + 1
    %CList{clist |
      list:
        :lists.sublist(clist.list, off, size(clist)-off+1)
        ++
        :lists.sublist(clist.list, 1, off),
      ptr: new_ptr
    }
  end

  @doc """
  Compare 2 `CList` and return true if the sequence obtained when traversing both lists are equal
  regardless of whether the original list is the same or not.
  """
  @spec equals?(left :: CList.t(), right :: CList.t()) :: boolean()
  def equals?(%CList{list: left}, %CList{list: right}) when length(left) != length(right), do: false
  def equals?(left, right) do
    # Look for the left CList in the list resulting of repeat 2 times the right CList
    list_contains_in_order?(
      take(right, size(right) * 2),
      to_list(left)
    )
    # left |> CList.ptr(1) |> Map.get(:list) == right |> CList.ptr(1) |> Map.get(:list)
  end

  # Credit for Alan and taken from
  # https://stackoverflow.com/questions/62711039/list-contains-another-list-in-the-same-order
  @spec list_contains_in_order?(List.t(), List.t()) :: boolean
  defp list_contains_in_order?([], _), do: false
  defp list_contains_in_order?(container, contained) do
    if List.starts_with?(container, contained) do
      true
    else
      list_contains_in_order?(tl(container), contained)
    end
  end

end

#################################################################################################
## Protocols implementations
#################################################################################################
defimpl Inspect, for: CList do
  import Inspect.Algebra
  def inspect(clist, opts) do
    concat(["#CList", to_doc( CList.to_list(clist), opts), "/#{clist.ptr}"])
  end
end

defimpl String.Chars, for: CList do
  def to_string(clist) do
    clist |> CList.to_list() |> String.Chars.to_string()
  end
end

defimpl Enumerable, for: CList do
  def count(clist) do
    clist |> CList.to_list() |> Enumerable.count()
  end

  def member?(clist, value) do
    {:ok, clist |> CList.to_list() |> Enum.member?(value)}
  end

  # For Streams
  def reduce(clist, {:cont, [{[], count}]} = acc, fun) do
    clist |>  CList.take(count) |> Enumerable.reduce(acc, fun)
  end
  # For CLists
  def reduce(clist, {:cont, {[], count}} = acc, fun) do
    clist |>  CList.take(count) |> Enumerable.reduce(acc, fun)
  end
  # Fallback trait CList as a common list
  def reduce(clist, acc, fun) do
    # IO.inspect {clist, acc, fun}
    clist |>  CList.to_list() |> Enumerable.reduce(acc, fun)
  end

  def slice(clist) do
    fun = &slicing_fun(clist, &1, &2, &3)
    {:ok, 9_999_999, fun}
  end

  defp slicing_fun(clist, start, amount, _step) do
    clist |> CList.ptr(start+1) |> CList.take(amount)
  end
end


#################################################################################################
defmodule TestCList do
  @moduledoc false
  use CList
  import CList, only: [match: 1, forward: 1]

  def hello do
    ["h", "e", "l", "l", "o", " ", "w", "o", "r", "l", "d", "! "]
      |> CList.new()
      |> say_hello_but_in_a_cool_way()
  end

  def say_hello_but_in_a_cool_way(cl, count \\ 5)
  def say_hello_but_in_a_cool_way(_, 0), do: IO.write("\n")
  def say_hello_but_in_a_cool_way( match([c | l]), count) do
    IO.write(c)
    :timer.sleep(200)
    say_hello_but_in_a_cool_way( forward(l), count - (c == "! " && 1 || 0))
  end
end
