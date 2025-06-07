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
          <label class="block text-sm font-medium text-gray-700">Poll Options</label>
          <div class="space-y-2">
            <.inputs_for :let={option_form} field={@form[:options]}>
              <div class="flex gap-2 items-start">
                <div class="flex-1">
                  <.input 
                    field={option_form[:text]} 
                    type="text" 
                    placeholder={"Option #{option_form.index + 1}"}
                  />
                </div>
                <button 
                  :if={length(@form[:options].value || []) > 2}
                  type="button" 
                  phx-click="remove_option" 
                  phx-value-index={option_form.index}
                  phx-target={@myself}
                  class="mt-2 p-1 text-red-500 hover:text-red-700 focus:outline-none"
                  title="Remove option"
                >
                  <svg class="w-4 h-4" fill="currentColor" viewBox="0 0 20 20">
                    <path fill-rule="evenodd" d="M4.293 4.293a1 1 0 011.414 0L10 8.586l4.293-4.293a1 1 0 111.414 1.414L11.414 10l4.293 4.293a1 1 0 01-1.414 1.414L10 11.414l-4.293 4.293a1 1 0 01-1.414-1.414L8.586 10 4.293 5.707a1 1 0 010-1.414z" clip-rule="evenodd"></path>
                  </svg>
                </button>
              </div>
            </.inputs_for>
          </div>
          
          <button 
            type="button" 
            phx-click="add_option" 
            phx-target={@myself}
            class="inline-flex items-center px-3 py-2 text-sm font-medium text-blue-600 bg-blue-50 border border-blue-200 rounded-md hover:bg-blue-100 focus:outline-none focus:ring-2 focus:ring-blue-500"
          >
            <svg class="w-4 h-4 mr-1" fill="currentColor" viewBox="0 0 20 20">
              <path fill-rule="evenodd" d="M10 3a1 1 0 011 1v5h5a1 1 0 110 2h-5v5a1 1 0 11-2 0v-5H4a1 1 0 110-2h5V4a1 1 0 011-1z" clip-rule="evenodd"></path>
            </svg>
            Add Option
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
    alias PulseVote.Polls.Poll.Option
    
    # Get current form params to preserve user input
    current_params = form_to_params(socket.assigns.form)
    existing_options = Map.get(current_params, "options", [])
    
    # Add new empty option
    new_options = existing_options ++ [%{"text" => "", "vote_count" => 0}]
    updated_params = Map.put(current_params, "options", new_options)
    
    changeset = 
      socket.assigns.poll
      |> Polls.change_poll(updated_params)
      |> Map.put(:action, :validate)
    
    {:noreply, assign(socket, form: to_form(changeset))}
  end

  def handle_event("remove_option", %{"index" => index_str}, socket) do
    index = String.to_integer(index_str)
    
    # Get current form params to preserve user input
    current_params = form_to_params(socket.assigns.form)
    existing_options = Map.get(current_params, "options", [])
    
    # Remove option at index
    new_options = List.delete_at(existing_options, index)
    updated_params = Map.put(current_params, "options", new_options)
    
    changeset = 
      socket.assigns.poll
      |> Polls.change_poll(updated_params)
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
    alias PulseVote.Polls.Poll.Option
    %{poll | options: [
      %Option{text: "", vote_count: 0},
      %Option{text: "", vote_count: 0}
    ]}
  end
  
  defp form_to_params(form) do
    # Extract params from form, preserving user input
    case form.source do
      %Ecto.Changeset{params: params} when params != %{} -> params
      %Ecto.Changeset{data: data} -> 
        # Convert struct data to params format
        data
        |> Map.from_struct()
        |> Map.update(:options, [], fn options ->
          Enum.map(options || [], fn option ->
            case option do
              %_{} -> Map.from_struct(option)
              map when is_map(map) -> map
            end
          end)
        end)
        |> stringify_keys()
      _ -> %{}
    end
  end
  
  defp stringify_keys(map) when is_map(map) do
    Enum.into(map, %{}, fn {k, v} -> {to_string(k), v} end)
  end
end
