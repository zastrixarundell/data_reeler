defmodule DataReeler.Fetchers.BrowserlessFetcher do
  require Logger
  
  @behaviour Crawly.Fetchers.Fetcher
  def fetch(request, options) do
    {base_url, options} =
      case Keyword.pop(options, :base_url) do
        {nil, _} ->
          "The base_url is not set. Splash fetcher can't be used! " <>
          "Please set :base_url in fetcher options to continue. " <>
          "For example: " <>
          "fetcher: {DataReeler.Fetchers.BrowserlessFetcher, [base_url: <url>]}"
          
        {base_url, other_options} ->
          {base_url, other_options}
      end
      
    {timeout, _options} = Keyword.pop(options, :timeout, 50_000)
    
    with {:ok, body} <- Jason.encode(%{url: request.url}),
         {:ok, response = %{body: _body, status_code: 200}} <- HTTPoison.post(base_url, body, [{"Content-Type", "application/json"}], [recv_timeout: timeout]) do
      new_request = %HTTPoison.Request{response.request | url: request.url}

      {
        :ok,
        %HTTPoison.Response{
          response |
          request: new_request,
          request_url: request.url
        }
      }
    else
      {:error, response} ->
        {:error, response}
      {:ok, response} ->
        {:error, response}
    end
  end
end