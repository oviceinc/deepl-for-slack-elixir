defmodule DeepThought.DeepL.API do
  @moduledoc """
  Module used to interact with the DeepL translation API.

  Requires `DEEPL_AUTH_KEY` in application config (from env). Uses the paid DeepL API;
  does not work with a free auth key.
  """

  @doc """
  Invoke DeepL's translation API, converting `text` into a translation in `target_language`.
  """
  @spec translate(String.t(), String.t()) :: {:ok, String.t()} | {:error, String.t()}
  def translate(text, target_language) do
    case client() |> Tesla.post("/translate", translate_request_body(text, target_language)) do
      {:ok, %{status: 200, body: body}} ->
        {:ok, Enum.at(body["translations"], 0)["text"]}

      _ ->
        {:error, "Failed to translate due to an unexpected response from translation server"}
    end
  end

  @spec translate_request_body(String.t(), String.t()) :: %{String.t() => String.t()}
  defp translate_request_body(text, target_language) do
    %{
      "text" => text,
      "target_lang" => target_language,
      "tag_handling" => "xml",
      "ignore_tags" => "c,d,e,l,u"
    }
  end

  defp client do
    config = module_config()

    middleware = [
      {Tesla.Middleware.BaseUrl, config[:endpoint] || "https://api.deepl.com/v2"},
      {Tesla.Middleware.Headers, [{"Authorization", "DeepL-Auth-Key #{config[:auth_key]}"}]},
      Tesla.Middleware.EncodeFormUrlencoded,
      Tesla.Middleware.DecodeJson,
      Tesla.Middleware.Logger,
      {Tesla.Middleware.Timeout, timeout: 10_000}
    ]

    Tesla.client(middleware, config[:adapter])
  end

  defp module_config do
    Enum.into(Application.get_env(:deep_thought, :deepl, []), %{})
  end
end
