defmodule DeepThought.DeepL.API do
  @moduledoc """
  Module used to interact with the DeepL translation API.

  Requires `DEEPL_AUTH_KEY` in application config (from env). Uses the paid DeepL API;
  does not work with a free auth key.
  """

  use Tesla

  @auth_key Application.compile_env(:deep_thought, :deepl, [])[:auth_key]

  plug Tesla.Middleware.BaseUrl, "https://api.deepl.com/v2"

  plug Tesla.Middleware.Headers, [
    {"Authorization", "DeepL-Auth-Key #{@auth_key}"}
  ]

  plug Tesla.Middleware.EncodeFormUrlencoded
  plug Tesla.Middleware.DecodeJson
  plug Tesla.Middleware.Logger
  plug Tesla.Middleware.Timeout, timeout: 10_000

  @doc """
  Invoke DeepL’s translation API, converting `text` into a translation in `target_language`.
  """
  @spec translate(String.t(), String.t()) :: {:ok, String.t()} | {:error, String.t()}
  def translate(text, target_language) do
    {:ok, response} = post("/translate", translate_request_body(text, target_language))

    case response.status() do
      200 ->
        {:ok, Enum.at(response.body()["translations"], 0)["text"]}

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
end
