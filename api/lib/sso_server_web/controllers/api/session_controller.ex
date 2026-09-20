defmodule SsoServerWeb.Api.SessionController do
  use SsoServerWeb, :controller

  alias Assent.Strategy.OIDC
  alias SsoServer.Accounts

  @doc "Starts OIDC sign-in by storing callback state and redirecting to the provider."
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

  @doc "Returns the user associated with the current session"
  def show(conn, _params) do
    conn =
      conn
      |> put_resp_header("cache-control", "no-store")
      |> put_resp_content_type("application/vnd.api+json")

    conn
    |> get_session(:user_id)
    |> case do
      nil ->
        unauthorized(conn)

      user_id ->
        respond_with_session_user(conn, user_id)
    end
  end

  @doc "Logs out by deleting the current application session."
  def delete(conn, _params) do
    conn
    |> clear_session()
    |> configure_session(drop: true)
    |> send_resp(:no_content, "")
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
            |> put_session(:user_id, user.id)
            |> redirect(external: Application.fetch_env!(:sso_server, :frontend_url))

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

  defp respond_with_session_user(conn, user_id) do
    case Accounts.get_user(user_id) do
      nil ->
        unauthorized(conn)

      user ->
        json(conn, %{
          data: user_resource(user),
          meta: %{csrfToken: get_csrf_token()}
        })
    end
  end

  defp unauthorized(conn) do
    conn
    |> put_status(:unauthorized)
    |> json(%{errors: [%{status: "401", title: "Not authenticated"}]})
  end

  defp user_resource(user) do
    %{
      type: "user",
      id: to_string(user.id),
      attributes: %{
        email: user.email,
        firstName: user.first_name,
        lastName: user.last_name
      }
    }
  end
end