class Api::V1::RoleController < ApplicationController
  skip_before_action :verify_authenticity_token
  def index
    roles = Role.all();
    render json: roles, status:200
  end
  
  def create
    ## get parameters
    name = params[:name]

    ## find record exist or not; if not create them
    role = Role.find_or_initialize_by(name: name)
    if !role.id
      role.name = name
      role.save
    end

    ##render json
    render json: role, status:200
  end

  def show
    render json: 1, status:200
  end
  
  def update
    ## get parameters
    permission = params[:permission]
    id = params[:id]

    ## verify user exist or not
    user = User.find_by(id: id)
    if !user
      render_json("There is no user exist with the provided ID: #{id}, Please provide the valid user to update role.", 400, 'message') and return
    end

    ## find role exist or not
    role = Role.find_by(name: permission)
    if !role
      render_json("There is no role exist with the provided permission: #{permission}, Please provide the valid role.", 400, 'message') and return
    end

    ## add role to the provided user
    user.add_role :"#{permission}"
    render json: role, status:200
  end
  
  def destroy
    ## get parameters
    id = params[:id]

    ## verify user exist or not
    user = User.find_by(id: id)
    if !user
      render_json("There is no user exist with the provided ID: #{id}, Please provide the valid user to update role.", 400, 'message') and return
    end

    ## delete the roles and return
    results = User.find_by_sql "DELETE FROM `users_roles` WHERE `user_id` = #{id}"
    # Role.where(user_id: id).delete_all
    render_json("User roles has been deleted Successfully.", 200, 'message') and return
  end

  # dafault funcation to render content
  ## this way we can add multiple render funcation on the comtroller otherwise DoubleRenderError was triggered
  def render_json(data, status_code, main_key = 'data')
    render json: { "#{main_key}": data }, status: status_code
  end
end
