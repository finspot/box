defmodule Box.Signature do
  def verify(payload, signature), do: verify(payload, signature, System.get_env("HMAC_SECRET"))

  def verify(payload, signature, secret) do
    expected_sig = :crypto.hmac(:sha256, secret, payload) |> Base.encode16()
    String.upcase(signature) == expected_sig
  end
end
