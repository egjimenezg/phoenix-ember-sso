defmodule SsoServer.Accounts do
  alias SsoServer.Repo
  alias SsoServer.Accounts.User

  @doc "Gets a user by ID."
  @spec get_user(integer()) :: User.t() | nil
  def get_user(id), do: Repo.get(User, id)

  @doc """
  Finds or create a user from OAuth attributes.

  Expects a map with `"email"` and `"name"` string keys
  """
  @spec find_or_create_from_oauth(map()) :: {:ok, User.t()} | {:error, Ecto.Changeset.t()}
  def find_or_create_from_oauth(%{"email" => email} = attrs) do
    case Repo.get_by(User, email: email) do
      nil ->
        %User{}
        |> User.changeset(%{
          email: email,
          first_name: attrs["given_name"] || attrs["name"],
          last_name: attrs["family_name"]
        })
        |> Repo.insert()

      user ->
        {:ok, user}
    end
  end
end
