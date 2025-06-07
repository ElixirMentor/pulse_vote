defmodule PulseVote.Polls.Poll do
  use Ecto.Schema
  import Ecto.Changeset

  defmodule Option do
    use Ecto.Schema
    import Ecto.Changeset

    embedded_schema do
      field :text, :string
      field :vote_count, :integer, default: 0
    end

    def changeset(option, attrs) do
      option
      |> cast(attrs, [:text, :vote_count])
      |> validate_required([:text])
    end
  end

  schema "polls" do
    field :description, :string
    field :title, :string
    embeds_many :options, Option

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(poll, attrs) do
    poll
    |> cast(attrs, [:title, :description])
    |> cast_embed(:options)
    |> validate_required([:title, :description])
    |> validate_length(:options, min: 2, message: "must have at least 2 options")
  end
end
