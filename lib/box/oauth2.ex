defmodule Box.OAuth2 do
  @token_url "https://api.box.com/oauth2/token"
  @box_sub_type "enterprise"
  @grant_type "urn:ietf:params:oauth:grant-type:jwt-bearer"

  def call(env, next, _opts) do
    env
    |> Tesla.Middleware.Headers.call([], %{
         "Authorization" => "Bearer #{token()}",
         "As-User" => user_id()
       })
    |> Tesla.run(next)
  end

  def token do
    Box.TokenCache.get() || fetch_and_store_token()
  end

  defp fetch_and_store_token do
    {token, ttl} = fetch_token()
    Box.TokenCache.store(token, ttl)
    token
  end

  defp fetch_token do
    %{status: 200, body: body} =
      Tesla.post(
        @token_url,
        "grant_type=#{@grant_type}&client_id=#{client_id()}&client_secret=#{client_secret()}&assertion=#{
          assertion()
        }"
      )

    %{"access_token" => token, "expires_in" => ttl} = Poison.decode!(body)
    {token, ttl}
  end

  # Configuration
  defp client_id, do: System.get_env("CLIENT_ID")
  defp client_secret, do: System.get_env("CLIENT_SECRET")
  defp enterprise_id, do: System.get_env("ENTERPRISE_ID")
  defp public_key_id, do: System.get_env("PUBLIC_KEY_ID")
  defp passphrase, do: System.get_env("PASSPHRASE")
  defp private_key, do: System.get_env("PRIVATE_KEY")
  defp user_id, do: System.get_env("USER_ID")

  # Decoding the private key into a JOSE-compatible key
  defp decoded_private_key do
    [encoded_key] =
      private_key()
      |> String.replace("\\n", "\n")
      |> :public_key.pem_decode()

    encoded_key
    |> :public_key.pem_entry_decode(passphrase())
    |> JOSE.JWK.from_key()
  end

  defp assertion do
    %{
      iss: client_id(),
      sub: enterprise_id(),
      box_sub_type: @box_sub_type,
      aud: @token_url,
      jti: Base.encode16(:crypto.strong_rand_bytes(64)),
      exp: Box.get_timestamp() + 10
    }
    |> Joken.token()
    |> Joken.with_header_arg("kid", public_key_id())
    |> Joken.with_signer(Joken.rs256(decoded_private_key()))
    |> Joken.sign()
    |> Map.fetch!(:token)
  end
end
