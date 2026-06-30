defmodule PulseVote.Repo.Migrations.AddUserIdToPolls do
  use Ecto.Migration

  def change do
    alter table(:polls) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
    end
    
    create index(:polls, [:user_id])
  end
end
