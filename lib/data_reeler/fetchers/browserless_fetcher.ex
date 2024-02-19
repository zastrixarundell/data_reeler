defmodule DataReeler.Fetchers.BrowserlessFetcher do
  require Logger
  
  @behaviour Crawly.Fetchers.Fetcher
  def fetch(request, options) do
    # configuration
    
    {base_url, options} =
      case Keyword.pop(options, :base_url) do
        {nil, _} ->
          throw(
            "The base_url is not set. Browserlerss.io fetcher can't be used! " <>
            "Please set :base_url in fetcher options to continue. " <>
            "For example: " <>
            "fetcher: {DataReeler.Fetchers.BrowserlessFetcher, [base_url: <url>]}"
          )
          
        {base_url, other_options} ->
          {base_url, other_options}
      end
      
    {timeout, _options} = Keyword.pop(options, :timeout, 50_000)
    
    # metadata for browserless.io
    
    decoded_uri =
      base_url
      |> URI.decode()
      |> URI.parse()
      
    cache_name = "--user-data-dir=/tmp/browserless-cache-#{decoded_uri.host}"
    
    rebuilt_url =
      decoded_uri
      |> URI.append_query(cache_name)
      |> URI.to_string()
    
    # http://localhost:3000/docs#tag/Browser-REST-APIs
    request = %{
      url: request.url,
      # Wait 500ms after last request, to make sure everything is loaded.
      gotoOptions: %{
        waitUntil: "networkidle0"
      },
    }
    
    with {:ok, body} <- Jason.encode(request),
         {:ok, response = %{body: _body, status_code: 200}} <- HTTPoison.post(rebuilt_url, body, [{"Content-Type", "application/json"}], [recv_timeout: timeout]) do
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