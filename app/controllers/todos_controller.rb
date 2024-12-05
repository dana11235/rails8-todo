require "openai"

class TodosController < ApplicationController
  skip_forgery_protection
  include ErrorHandling

  def index
    todos = nil
    if params[:completed]
      todos = Todo.where.not(completed_at: nil)
    elsif params[:deleted]
      todos = Todo.where.not(deleted_at: nil)
    else
      todos = Todo.where(deleted_at: nil)
    end
    render :json => todos
  end

  def create
    todo = Todo.create!(todo_params)
    render :json => todo
  rescue ActiveRecord::RecordInvalid => e
    respond_with_error(e.record)
  end

  def generate_from_gpt
    if params["subject"] && params["num"]
      client = OpenAI::Client.new(
        access_token: ENV["OPENAI_TOKEN"],
        organization_id: ENV["OPENAI_ORG_ID"],
        log_errors: true, # Highly recommended in development, so you can see what errors OpenAI is returning. Not recommended in production because it could leak private data to your logs.
      )

      prompt = "Please generate only #{params["num"]} tasks, returning only a comma separated list of strings with no quotes, related to the following subject: #{params["subject"]}"

      response = client.chat(parameters: {
                               model: "gpt-4o-mini-2024-07-18",
                               messages: [{
                                 role: "user",
                                 content: prompt,
                               }],
                               temperature: 0.7,
                             })

      response_content = response["choices"][0]["message"]["content"]
      tasks = response_content.split(",")
      new_todos = []
      tasks.each do |task|
        new_todos << Todo.create({ :description => task.strip })
      end
      render :json => new_todos
    end
  end

  def get
    render :json => Todo.find(params[:id])
  end

  def update
    todo = Todo.find(params[:id])
    if todo_params[:description]
      todo.description = todo_params[:description]
    end
    if todo_params[:completed]
      todo.completed_at = Time.now
    end
    todo.save!
    render :json => todo
  end

  def destroy_all
    Todo.update_all({ deleted_at: Time.now })
  end

  def destroy
    todo = Todo.find(params[:id])
    todo.update({ deleted_at: Time.now })
  end

  private

  def todo_params
    params.permit(:description, :completed)
  end
end
