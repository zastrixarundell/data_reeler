defmodule DataReeler.Crawler do
  defmacro __using__(_) do
    quote do
      use Crawly.Spider

      require Logger
      
      defp blank?(nil), do: true
      defp blank?(""), do: true
      defp blank?(_), do: false
    end
  end
end