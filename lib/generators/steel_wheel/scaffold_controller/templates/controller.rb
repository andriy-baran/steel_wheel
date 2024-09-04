<% module_namespacing do -%>
  class <%= controller_class_name %>Controller < ApplicationController
    # GET <%= route_url %>
    def index
      @context = <%= controller_class_name %>::IndexHandler.handle(input: params)
    end

    # GET <%= route_url %>/1
    def show
      @context = <%= controller_class_name %>::ShowHandler.handle(input: params)
    end

    # GET <%= route_url %>/new
    def new
      @context = <%= controller_class_name %>::NewHandler.handle(input: params)
      @errors = @context.errors
    end

    # GET <%= route_url %>/1/edit
    def edit
      @context = <%= controller_class_name %>::EditHandler.handle(input: params)
      @errors = @context.errors
    end

    # POST <%= route_url %>
    def create
      @context = <%= controller_class_name %>::CreateHandler.handle(input: params)
      if @context.success?
        redirect_to @context.<%= singular_table_name %>, notice: <%= %("#{human_name} was successfully created.") %>
      else
        @errors = @context.errors
        render :new, status: :unprocessable_entity
      end
    end

    # PATCH/PUT <%= route_url %>/1
    def update
      @context = <%= controller_class_name %>::UpdateHandler.handle(input: params)
      if @context.success?
        redirect_to @context.<%= singular_table_name %> notice: <%= %("#{human_name} was successfully created.") %>
      else
        @errors = @context.errors
        render :edit, status: :unprocessable_entity
      end
    end

    # DELETE <%= route_url %>/1
    def destroy
      <%= controller_class_name %>::DestroyHandler.handle(input: params)
      redirect_to <%= index_helper %>_path, notice: <%= %("#{human_name} was successfully destroyed.") %>, status: :see_other
    end

    private
      # Use callbacks to share common setup or constraints between actions.
      def set_<%= singular_table_name %>
        @<%= singular_table_name %> = <%= orm_class.find(class_name, "params[:id]") %>
      end

      # Only allow a list of trusted parameters through.
      def <%= "#{singular_table_name}_params" %>
        <%- if attributes_names.empty? -%>
        params.fetch(:<%= singular_table_name %>, {})
        <%- else -%>
        params.require(:<%= singular_table_name %>).permit(<%= permitted_params %>)
        <%- end -%>
      end
  end
  <% end -%>
