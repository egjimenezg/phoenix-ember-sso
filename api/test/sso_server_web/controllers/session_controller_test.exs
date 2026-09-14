defmodule SsoServerWeb.Api.SessionControllerTest do
  use SsoServerWeb.ConnCase, async: true

  alias SsoServer.Accounts.User
  alias SsoServer.Repo

  test "GET /auth/google redirects to the OAuth authorization endpoint", %{conn: conn} do
    conn = get(conn, "/auth/google")

    assert redirected_to(conn, 302) =~ "accounts.google.com"
    assert get_session(conn, :oauth_state)
  end

  @tag :integration
  test "GET /auth/google/callback exchanges code with mock and creates user", %{conn: conn} do
    # Step 1: hit our request action to get the authorize URL and CSRF state
    conn_request = get(conn, "/auth/google")
    authorize_url = redirected_to(conn_request, 302)
    session_params = get_session(conn_request, :oauth_state)

    # Step 2: hit the mock's authorize endpoint — it auto-redirects to our
    # callback URL with ?code=...&state=... without starting a browser
    {:ok, response} = Req.get(authorize_url, redirect: false)
    [location] = response.headers["location"]

    %URI{query: query} = URI.parse(location)
    %{"code" => code, "state" => state} = URI.decode_query(query)

    # Step 3: call our callback with the code and the session state from step 1
    conn_callback =
      conn
      |> Plug.Test.init_test_session(%{oauth_state: session_params})
      |> get("/auth/google/callback", %{"code" => code, "state" => state})

    assert redirected_to(conn_callback, 302) == "http://localhost:4200"

    user = Repo.get_by!(User, email: "testuser@example.com")

    assert get_session(conn_callback, :user_id) == user.id
    refute get_session(conn_callback, :oauth_state)
  end
end
