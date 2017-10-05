# ets-powered key-value cache with expiration
defmodule Box.TokenCache do
  @cache_table __MODULE__
  @cache_key :box_oauth2_token

  def child_spec(_args) do
    %{
      id: __MODULE__,
      start: { __MODULE__, :start_link, []},
      restart: :permanent,
      shutdown: 5000,
      type: :worker
     }
  end

  def start_link do
    :ets.new(@cache_table, [:set, :public, :named_table])
    {:ok, self()}
  end

  @doc """
  Fetches a stored token, handling expiration
  iex> Box.TokenCache.store("mytoken", 3600)
  :ok
  iex> Box.TokenCache.get()
  "mytoken"
  iex> Box.TokenCache.get(Box.get_timestamp() + 3800)
  nil
  """
  def get, do: get(Box.get_timestamp())
  def get(now) do
    case :ets.lookup(@cache_table, @cache_key) do
      [{@cache_key, {_token, exp}}] when now > exp -> nil
      [{@cache_key, {token, _exp}}] -> token
      [] -> nil
    end
  end

  def store(token, ttl) do
    # 1 minute leeway
    exp = Box.get_timestamp + ttl - 60
    :ets.insert(@cache_table, {@cache_key, {token, exp}})
    :ok
  end
end
