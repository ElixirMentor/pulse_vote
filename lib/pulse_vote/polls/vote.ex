defmodule PulseVote.Polls.Vote do
  use Ecto.Schema
  import Ecto.Changeset

  schema "votes" do
    field :option_index, :integer
    belongs_to :poll, PulseVote.Polls.Poll
    belongs_to :user, PulseVote.Accounts.User

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(vote, attrs) do
    vote
    |> cast(attrs, [:option_index, :poll_id, :user_id])
    |> validate_required([:option_index, :poll_id, :user_id])
    |> unique_constraint([:poll_id, :user_id], message: "You have already voted on this poll")
  end
end
