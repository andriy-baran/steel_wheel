class <%= controller_class_name %>Controller < ApplicationController
  before_action :authenticate_account!

  # GET <%= route_url %>
  action :index do |handler|
    @<%= plural_table_name %> = handler.<%= plural_table_name %>
    @form = handler.form
  end

  # GET <%= route_url %>/1
  action :show, handler: :update do |handler|
    @<%= singular_table_name %> = handler.<%= singular_table_name %>
  end

  # GET <%= route_url %>/new
  action :new, handler: :create do |handler|
    @<%= singular_table_name %> = handler.<%= singular_table_name %>
    @form = handler.form
  end

  # GET <%= route_url %>/1/edit
  action :edit, handler: :update do |handler|
    @<%= singular_table_name %> = handler.<%= singular_table_name %>
    @form = handler.form
  end

  # POST <%= route_url %>
  action :create, act: :call do |handler|
    handler.success do
      redirect_to handler.<%= singular_table_name %>, notice: '<%= human_name %> was successfully created.'
    end

    handler.failure do
      @<%= singular_table_name %> = handler.<%= singular_table_name %>
      @form = handler.form
      render :new
    end
  end

  # PATCH/PUT <%= route_url %>/1
  action :update, act: :call do |handler|
    handler.success do
      redirect_to handler.<%= singular_table_name %>, notice: '<%= human_name %> was successfully updated.'
    end

    handler.failure do
      @form = handler.form
      @<%= singular_table_name %> = handler.<%= singular_table_name %>
      render :edit
    end
  end

  # DELETE <%= route_url %>/1
  action :destroy, handler: :update, act: :destroy do |handler|
    redirect_to <%= index_helper %>_url, notice: '<%= human_name %> was successfully destroyed.'
  end
end
