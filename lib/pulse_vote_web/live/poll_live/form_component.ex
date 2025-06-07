defmodule PulseVoteWeb.PollLive.FormComponent do
  use PulseVoteWeb, :live_component

  alias PulseVote.Polls

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        {@title}
        <:subtitle>Create a new poll with multiple options for users to vote on.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="poll-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:title]} type="text" label="Poll Title" placeholder="What's your question?" />
        <.input field={@form[:description]} type="textarea" label="Description (optional)" placeholder="Add more details about your poll..." />
        
        <div class="space-y-3">
          <label class="block text-sm font-medium text-gray-700">Options</label>
          <.inputs_for :let={option_form} field={@form[:options]}>
            <div class="flex gap-2 items-center">
              <.input 
                field={option_form[:text]} 
                type="text" 
                placeholder={"Option #{option_form.index + 1}"} 
                class="flex-1"
              />
              <button 
                type="button" 
                phx-click="remove_option" 
                phx-value-index={option_form.index}
                phx-target={@myself}
                class="text-red-500 hover:text-red-700"
              >
                ✕
              </button>
            </div>
          </.inputs_for>
          
          <button 
            type="button" 
            phx-click="add_option" 
            phx-target={@myself}
            class="text-blue-500 hover:text-blue-700 text-sm"
          >
            + Add Option
          </button>
        </div>
        
        <:actions>
          <.button phx-disable-with="Creating...">Create Poll</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{poll: poll} = assigns, socket) do
    poll = ensure_default_options(poll)
    
    {:ok,
     socket
     |> assign(assigns)
     |> assign_new(:form, fn ->
       to_form(Polls.change_poll(poll))
     end)}
  end

  @impl true
  def handle_event("validate", %{"poll" => poll_params}, socket) do
    changeset = Polls.change_poll(socket.assigns.poll, poll_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("add_option", _params, socket) do
    existing_options = socket.assigns.form.source.changes[:options] || socket.assigns.poll.options || []
    new_options = existing_options ++ [%{text: "", vote_count: 0}]
    
    changeset = 
      socket.assigns.poll
      |> Polls.change_poll(%{options: new_options})
      |> Map.put(:action, :validate)
    
    {:noreply, assign(socket, form: to_form(changeset))}
  end

  def handle_event("remove_option", %{"index" => index_str}, socket) do
    index = String.to_integer(index_str)
    existing_options = socket.assigns.form.source.changes[:options] || socket.assigns.poll.options || []
    new_options = List.delete_at(existing_options, index)
    
    changeset = 
      socket.assigns.poll
      |> Polls.change_poll(%{options: new_options})
      |> Map.put(:action, :validate)
    
    {:noreply, assign(socket, form: to_form(changeset))}
  end

  def handle_event("save", %{"poll" => poll_params}, socket) do
    save_poll(socket, socket.assigns.action, poll_params)
  end

  defp save_poll(socket, :edit, poll_params) do
    case Polls.update_poll(socket.assigns.poll, poll_params) do
      {:ok, poll} ->
        notify_parent({:saved, poll})

        {:noreply,
         socket
         |> put_flash(:info, "Poll updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_poll(socket, :new, poll_params) do
    case Polls.create_poll(poll_params) do
      {:ok, poll} ->
        notify_parent({:saved, poll})

        {:noreply,
         socket
         |> put_flash(:info, "Poll created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
  
  defp ensure_default_options(%{options: options} = poll) when is_list(options) and length(options) > 0 do
    poll
  end
  
  defp ensure_default_options(poll) do
    %{poll | options: [
      %{text: "", vote_count: 0},
      %{text: "", vote_count: 0}
    ]}
  end
end
