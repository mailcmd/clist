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

  def new([_] = list) do
    [h | t] = list
    %RList{list: [h | (t ++ [h])], ptr: 1}
  end
  def new(_.._//_ = range) do
    range |> Range.to_list() |> new()
  end

  def from_range(_.._//_ = range), do: new(range)

  def size(rlist) do
    length(rlist.list) - 1
  end

  def to_tuple(rlist) do
    List.to_tuple(to_list(rlist))
  end

  def take(_, 0), do: []
  def take(rlist, count) do
    {value, rlist} = next(rlist)
    [ value ] ++ take(rlist, count - 1)
  end

  def reset(rlist) do
    new(Enum.slice(rlist, rlist.ptr-1, length(rlist.list)) ++ Enum.slice(rlist, 0, rlist.ptr-1))
  end

  def next(rlist) do
    match([value | _]) = rlist
    new_rlist = rotate(rlist)
    {value , new_rlist}
  end

  def rotate(rlist) do
    len = size(rlist)
    %RList{list: [_ | [h | t]], ptr: ptr} = rlist
    ptr = ptr == len && 1 || (ptr + 1)
    %RList{list: [h | (t ++ [h])], ptr: ptr}
  end

  def to_list(rlist) do
    Enum.slice(rlist.list, 0, size(rlist))
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

  def reduce(rlist, acc, fun) do
    rlist.list |>  RList.to_list() |> Enumerable.List.reduce(acc, fun)
  end

  def slice(rlist) do
    len = RList.size(rlist)
    {:ok, len, &RList.to_list/1}
  end
end


#################################################################################################
defmodule Tests2 do
  use RList

  def test(match [h | t]) do
    IO.puts "H: #{h}"
    IO.inspect t, label: "T"
    :timer.sleep(1000)
    test(rotate t)
  end
end
