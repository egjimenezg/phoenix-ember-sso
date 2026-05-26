defmodule SsoServerWeb.Api.SessionControllerTest do
  use SsoServerWeb.ConnCase, async: true

  test "GET /auth/google redirects to Google OAuth", %{conn: conn} do
    conn = get(conn, "/auth/google")

    assert redirected_to(conn) =~ "https://accounts.google.com"
    assert get_session(conn, :oauth_state)
  end
end
