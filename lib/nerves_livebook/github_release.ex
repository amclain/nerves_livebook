defmodule NervesLivebook.GithubRelease do
  @moduledoc """
  Check for firmware updates from the Github releases of the NervesLivebook
  repo. See `firmware_update.livemd` for usage.
  """

  @github_api_url "https://api.github.com"

  @type t() :: map()

  @doc """
  Request the latest release information from GitHub
  """
  @spec get_latest(String.t()) :: {:ok, t()} | {:error, any()}
  def get_latest(repository) do
    url = "#{@github_api_url}/repos/#{repository}/releases/latest"
    headers = [{'user-agent', user_agent()}]
    request = {String.to_charlist(url), headers}
    http_options = []
    options = [body_format: :binary]

    case :httpc.request(:get, request, http_options, options) do
      {:ok, {{_, 200, _}, _headers, body}} ->
        {:ok, Jason.decode!(body)}

      other ->
        {:error, other}
    end
  end

  @doc """
  Return the release version as a string
  """
  @spec version(t()) :: String.t() | :error
  def version(release) do
    case release["tag_name"] do
      # Release version tags have a 'v', so if this doesn't follow the convention then
      # something is wrong.
      "v" <> version -> version
      _ -> :error
    end
  end

  @doc """
  Helper function for getting the firmware filename
  """
  @spec firmware_filename(String.t() | atom(), String.t() | atom()) :: String.t()
  def firmware_filename(app_name, target) do
    "#{app_name}_#{target}.fw"
  end

  @doc """
  Return the URL for downloading the firmware for a target

  If the target firmware isn't available, it returns an error
  """
  @spec firmware_url(t(), String.t() | atom(), String.t() | atom()) ::
          {:ok, String.t()} | {:error, :not_found}
  def firmware_url(release, app_name, target) do
    filename = firmware_filename(app_name, target)

    case Enum.find(release["assets"], fn m -> m["name"] == filename end) do
      %{"browser_download_url" => url} -> {:ok, url}
      _ -> {:error, :not_found}
    end
  end

  defp user_agent() do
    'NervesLivebook/#{NervesLivebook.version()}'
  end
end
