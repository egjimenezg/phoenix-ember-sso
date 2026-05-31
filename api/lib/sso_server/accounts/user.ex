defmodule SsoServer.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field :email, :string
    field :first_name, :string
    field :middle_name, :string
    field :last_name, :string
    field :second_last_name, :string

    timestamps(type: :utc_datetime)
  end

  @required_fields [:email, :first_name]
  @optional_fields [:middle_name, :last_name, :second_last_name]

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> unique_constraint(:email)
  end
end
