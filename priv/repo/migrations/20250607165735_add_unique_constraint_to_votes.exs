defmodule PulseVote.Repo.Migrations.AddUniqueConstraintToVotes do
  use Ecto.Migration

  def change do
    create unique_index(:votes, [:poll_id, :user_id])
  end
end
