defmodule SsoServerWeb.Api.SessionControllerTest do
  use SsoServerWeb.ConnCase, async: true

  alias SsoServer.Accounts.User
  alias SsoServer.Accounts
  alias SsoServer.Repo

  describe "GET /api/session" do
    test "returns the authenticated user", %{conn: conn} do
      {:ok, %{id: user_id}} = Accounts.find_or_create_from_oauth(%{
        "email" => "signed-in@example.com",
        "given_name" => "Signed",
        "family_name" => "In"
      })

      conn =
        conn
        |> Plug.Test.init_test_session(%{user_id: user_id})
        |> get("/api/session")

      assert %{
              "user" => %{
                "id" => ^user_id,
                "email" => "signed-in@example.com",
                "first_name" => "Signed",
                "last_name" => "In"
              }
      } = json_response(conn, 200)
    end

    test "returns unauthorized without a session", %{conn: conn} do
      conn = get(conn, "/api/session")
      assert %{"error" => "Not authenticated"} = json_response(conn, 401)
    end

    test "returns unauthorized when the session user no longer exists", %{conn: conn} do
      conn =
        conn
        |> Plug.Test.init_test_session(%{user_id: 0})
        |> get("/api/session")

      assert %{"error" => "Not authenticated"} = json_response(conn, 401)
    end
  end

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
