defmodule SsoServer.Accounts do
  alias SsoServer.Repo
  alias SsoServer.Accounts.User

  @doc """
  Finds or create a user from OAuth attributes.

  Expects a map with `"email"` and `"name"` string keys
  """
  @spec find_or_create_from_oauth(map()) :: {:ok, User.t()} | {:error, Ecto.Changeset.t()}
  def find_or_create_from_oauth(%{"email" => email, "name" => name}) do
    case Repo.get_by(User, email: email) do
      nil ->
        %User{}
        |> User.changeset(%{email: email, name: name})
        |> Repo.insert()

      user ->
        {:ok, user}
    end
  end
end
