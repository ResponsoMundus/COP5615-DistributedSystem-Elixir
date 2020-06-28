defmodule Proj42Web.UserController do
    use Proj42Web, :controller
  
    def info(conn, %{"userid" => userid}) do
        render(conn, "info.html", userid: userid)
    end

    def login(conn, _params) do
        render(conn, "login.html")
    end

    def register(conn, _params) do
        render(conn, "register.html")
    end

    def subscribe(conn, %{"userid" => userid}) do
        render(conn, "subscribe.html", userid: userid)
    end

    def tweet(conn, _params) do
        render(conn, "tweet.html")
    end

    def search(conn, _params) do
        render(conn, "search.html")
    end
end
  
