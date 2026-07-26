defmodule SsoServerWeb.Api.SessionController do
  use SsoServerWeb, :controller

  alias Assent.Strategy.OIDC
  alias SsoServer.Accounts

  def request(conn, _params) do
    oauth_config()
    |> OIDC.authorize_url()
    |> case do
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

  def callback(conn, params) do
    session_params = get_session(conn, :oauth_state) || %{}

    result =
      oauth_config()
      |> Keyword.put(:session_params, session_params)
      |> OIDC.callback(params)

    case result do
      {:ok, %{user: user_info}} ->
        case Accounts.find_or_create_from_oauth(user_info) do
          {:ok, user} ->
            conn
            |> delete_session(:oauth_state)
            |> json(%{user: %{id: user.id, email: user.email, first_name: user.first_name, last_name: user.last_name}})

          {:error, changeset} ->
            conn
            |> put_status(:unprocessable_entity)
            |> json(%{error: "Could not persist user", detail: inspect(changeset.errors)})
        end

      {:error, reason} ->
        conn
        |> put_status(:bad_request)
        |> json(%{error: "OAuth callback failed", detail: inspect(reason)})
    end
  end

  defp oauth_config do
    config = Application.fetch_env!(:sso_server, :google_oauth)

    [
      client_id: config[:client_id],
      client_secret: config[:client_secret],
      redirect_uri: config[:redirect_uri],
      base_url: config[:base_url],
      authorization_params: [scope: "openid email profile"],
      client_authentication_method: "client_secret_post"
    ]
  end
end
