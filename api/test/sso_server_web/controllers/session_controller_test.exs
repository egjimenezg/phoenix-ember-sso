defmodule SsoServerWeb.Api.SessionControllerTest do
  use SsoServerWeb.ConnCase, async: true

  alias SsoServer.Accounts.User
  alias SsoServer.Accounts
  alias SsoServer.Repo

  describe "GET /api/session" do
    test "returns the authenticated user", %{conn: conn} do
      {:ok, %{id: user_id}} =
        Accounts.find_or_create_from_oauth(%{
          "email" => "signed-in@example.com",
          "given_name" => "Signed",
          "family_name" => "In"
        })

      conn =
        conn
        |> Plug.Test.init_test_session(%{user_id: user_id})
        |> get("/api/session")

      assert %{
               "data" => %{
                 "type" => "user",
                 "id" => user_id_as_string,
                 "attributes" => %{
                   "email" => "signed-in@example.com",
                   "firstName" => "Signed",
                   "lastName" => "In"
                 }
               },
               "meta" => %{"csrfToken" => csrf_token}
             } = json_response(conn, 200)

      assert user_id_as_string == to_string(user_id)
      assert is_binary(csrf_token)
      assert get_resp_header(conn, "content-type") == ["application/vnd.api+json; charset=utf-8"]
    end

    test "returns unauthorized without a session", %{conn: conn} do
      conn = get(conn, "/api/session")

      assert %{"errors" => [%{"status" => "401", "title" => "Not authenticated"}]} =
               json_response(conn, 401)
    end

    test "returns unauthorized when the session user no longer exists", %{conn: conn} do
      conn =
        conn
        |> Plug.Test.init_test_session(%{user_id: 0})
        |> get("/api/session")

      assert %{"errors" => [%{"status" => "401", "title" => "Not authenticated"}]} =
               json_response(conn, 401)
    end
  end

  describe "DELETE /api/session" do
    test "clears the authenticated session", %{conn: conn} do
      {:ok, user} =
        Accounts.find_or_create_from_oauth(%{
          "email" => "logout@example.com",
          "given_name" => "Logout"
        })

      conn =
        conn
        |> Plug.Test.init_test_session(%{user_id: user.id})
        |> get("/api/session")

      %{"meta" => %{"csrfToken" => token}} = json_response(conn, 200)

      conn =
        conn
        |> recycle()
        |> put_req_header("x-csrf-token", token)
        |> put_private(:plug_skip_csrf_protection, false)
        |> delete("/api/session")

      assert response(conn, 204)
      refute get_session(conn, :user_id)

      assert conn |> recycle() |> get("/api/session") |> json_response(401) == %{
               "errors" => [%{"status" => "401", "title" => "Not authenticated"}]
             }
    end

    test "rejects logout without a CSRF token", %{conn: conn} do
      conn = put_private(conn, :plug_skip_csrf_protection, false)
      assert_error_sent 403, fn -> delete(conn, "/api/session") end
    end

    test "allows credentialed logout preflight from Ember", %{conn: conn} do
      conn =
        conn
        |> put_req_header("origin", "http://localhost:4200")
        |> put_req_header("access-control-request-method", "DELETE")
        |> put_req_header("access-control-request-headers", "x-csrf-token")
        |> options("/api/session")

      assert conn.status == 204
      assert get_resp_header(conn, "access-control-allow-origin") == ["http://localhost:4200"]
      assert get_resp_header(conn, "access-control-allow-credentials") == ["true"]
    end
  end

  test "GET /auth/google redirects to the OAuth authorization endpoint", %{conn: conn} do
    conn = get(conn, "/auth/google")

    redirect_uri =
      conn
      |> redirected_to(302)
      |> URI.parse()

    provider_uri =
      :sso_server
      |> Application.fetch_env!(:google_oauth)
      |> Keyword.fetch!(:base_url)
      |> URI.parse()

    assert redirect_uri.host == provider_uri.host
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

    assert conn_callback.status == 302,
           "expected OAuth callback to redirect, got: #{conn_callback.resp_body}"

    assert redirected_to(conn_callback, 302) == "http://localhost:4200"

    user = Repo.get_by!(User, email: "testuser@example.com")

    assert get_session(conn_callback, :user_id) == user.id
    refute get_session(conn_callback, :oauth_state)
  end
end
