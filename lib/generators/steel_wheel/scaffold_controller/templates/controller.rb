class <%= controller_class_name %>Controller < ApplicationController
  before_action :authenticate_account!

  # GET <%= route_url %>
  action :index do |handler|
    @<%= controller_file_name %> = handler.<%= controller_file_name %>
    @form = handler.form
  end

  # GET <%= route_url %>/1
  action :show, handler: :update do |handler|
    @<%= file_name %> = handler.<%= file_name %>
  end

  # GET <%= route_url %>/new
  action :new, handler: :create do |handler|
    @<%= file_name %> = handler.<%= file_name %>
    @form = handler.form
  end

  # GET <%= route_url %>/1/edit
  action :edit, handler: :update do |handler|
    @<%= file_name %> = handler.<%= file_name %>
    @form = handler.form
  end

  # POST <%= route_url %>
  action :create do |handler|
    handler.success do
      <%- if controller_class_path.empty? -%>
      redirect_to handler.<%= file_name %>, notice: '<%= human_name %> was successfully created.'
      <%- else -%>
      redirect_to [<%= controller_class_path.map{|path| ":#{path}"}.join(', ') %>, handler.<%= file_name %>], notice: '<%= human_name %> was successfully created.'
      <%- end -%>
    end

    handler.failure do
      @<%= file_name %> = handler.<%= file_name %>
      @form = handler.form
      render :new
    end
  end

  # PATCH/PUT <%= route_url %>/1
  action :update do |handler|
    handler.success do
      <%- if controller_class_path.empty? -%>
      redirect_to handler.<%= file_name %>, notice: '<%= human_name %> was successfully updated.'
      <%- else -%>
      redirect_to [<%= controller_class_path.map{|path| ":#{path}"}.join(', ') %>, handler.<%= file_name %>], notice: '<%= human_name %> was successfully updated.'
      <%- end -%>
    end

    handler.failure do
      @form = handler.form
      @<%= file_name %> = handler.<%= file_name %>
      render :edit
    end
  end

  # DELETE <%= route_url %>/1
  action :destroy, handler: :update do |handler|
    redirect_to <%= index_helper %>_url, notice: '<%= human_name %> was successfully destroyed.'
  end
end
