defmodule DataReeler.Fetchers.BrowserlessFetcher do
  require Logger
  
  @behaviour Crawly.Fetchers.Fetcher
  def fetch(request, options) do
    # configuration
    
    base_url = Application.get_env(:data_reeler, :browserless_fetcher)
      
    {timeout, _options} = Keyword.pop(options, :timeout, 50_000)
    
    # http://localhost:3000/docs#tag/Browser-REST-APIs
    request = %{
      url: request.url,
      # Wait 500ms after last request, to make sure everything is loaded.
      gotoOptions: %{
        waitUntil: "networkidle0"
      },
    }
    
    with {:ok, body} <- Jason.encode(request),
         {:ok, response = %{body: _body, status_code: 200}} <- HTTPoison.post(base_url, body, [{"Content-Type", "application/json"}], [recv_timeout: timeout, follow_redirect: true]) do
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