defmodule DataReeler.Utils.CrawlerHelpers do  
  def barcode_extraction([], %Regex{}) do
    nil
  end
  
  def barcode_extraction(floki_elements, %Regex{} = regex) do
    floki_elements
    |> Enum.find_value(fn floki_element ->
        floki_element
        |> Floki.text(deep: true)
        |> then(&Regex.run(regex, &1))
        |> List.wrap()
        |> List.last()
      end)
  end
  
  def normalize_price(price) when is_bitstring(price) do
    price
    |> String.replace(~r/[,.]/, "")
    |> String.to_integer()
    |> Kernel./(100.00)
  end
  
  def normalize_price(_) do
    -1
  end
end