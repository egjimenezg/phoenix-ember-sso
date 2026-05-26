defmodule SsoServerWeb.Api.SessionController do
  use SsoServerWeb, :controller

  @doc """
  GET /auth/google
  Builds the Google OAuth authorization URL and redirects user to it
  """
  def request(conn, _params) do
    case Assent.Strategy.Google.authorize_url(google_config()) do
      {:ok, %{url: url, session_params: session_params}} ->
        conn
        |> put_session(:oauth_state, session_params)
        |> redirect(external: url)

      {:error, reason} ->
        conn
        |> put_status(:internal_server_error)
        |> json(%{error: "Could not build OAuth URL", detail: inspect(reason)})
    end
  end

  defp google_config do
    config = Application.fetch_env!(:sso_server, :google_oauth)

    [
      client_id: config[:client_id],
      client_secret: config[:client_secret],
      redirect_uri: config[:redirect_uri],
      scope: "openid email profile"
    ]
  end
end
