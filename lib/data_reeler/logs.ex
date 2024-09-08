defmodule DataReeler.Logs do
  @moduledoc """
  The context for logging into the database.
  """

  import Ecto.Query, warn: false
  require Logger
  
  alias DataReeler.Repo
  alias DataReeler.Logs.CrawlerAccess
  
  def log_crawler_access(nil, cralwer_name) do
    log_crawler_access(cralwer_name)
  end
  
  def log_crawler_access(aao, crawler_name) do
    aao_date = aao |> NaiveDateTime.to_date()
    date_now = Date.utc_today()
    
    if (aao_date == date_now) do
      Logger.debug("Product date already logged.")
      :ok
    else
      log_crawler_access(crawler_name)
    end
  end
  
  defp log_crawler_access(crawler_name) do
    potential_log =
      Repo.one(
        from ca in CrawlerAccess,
          where: ca.crawler_name == ^crawler_name,
          where: fragment("CAST(inserted_at AS DATE) = CAST(NOW() AS DATE)"),
          select: ca.id
      )
      
    case potential_log do
      nil ->
        Logger.debug("No #{crawler_name} log found for today... Creating one")
        
        insert_resp =
          %CrawlerAccess{}
          |> CrawlerAccess.changeset(%{crawler_name: crawler_name})
          |> Repo.insert()
          
        case insert_resp do
          {:ok, _} ->
            :ok
            
          {:error, reason} ->
            {:error, :failed_log, reason}
        end

      log_id ->
        Logger.debug("#{crawler_name} log found for today, incrementing")
        
        query =
          from ca in CrawlerAccess,
            where: ca.id == ^log_id
        
        Repo.update_all(
          query,
          inc: [access_count: 1]
        )
        
        :ok
    end
  end
end
