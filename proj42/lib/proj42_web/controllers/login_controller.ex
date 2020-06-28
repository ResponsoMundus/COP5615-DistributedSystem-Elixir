defmodule Proj42Web.LoginController do
    use Proj42Web, :controller
    alias Proj42Web.User

    def new(conn, _params) do
        render(conn, "new.html")
    end

    def create(conn, %{"_csrf_token" => _csrf, "_utf8" => _utf, 
        "session" => %{"username" => username, "password" => password}}) do
        conn
        |> put_flash(:info, "New user created!")
        |> redirect(to: Routes.user_path(conn, :index, username))
    end

end