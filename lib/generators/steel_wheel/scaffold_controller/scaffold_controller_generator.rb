module SteelWheel
  class ScaffoldControllerGenerator < Rails::Generators::NamedBase
      include Rails::Generators::ResourceHelpers

      source_root File.expand_path('templates', __dir__)

      check_class_collision suffix: "Controller"

      class_option :helper, type: :boolean
      class_option :orm, banner: "NAME", type: :string, required: true,
                         desc: "ORM to generate the controller for"
      class_option :api, type: :boolean,
                         desc: "Generate API controller"

      class_option :skip_routes, type: :boolean, desc: "Don't add routes to config/routes.rb."

      argument :attributes, type: :array, default: [], banner: "field:type field:type"

      def create_controller_files
        template_file = options.api? ? "api_controller.rb" : "controller.rb"
        template template_file, File.join("app/controllers", controller_class_path, "#{controller_file_name}_controller.rb")
      end

      def copy_template
        if behavior == :revoke
          template 'form.tt', "lib/templates/erb/scaffold/_form.html.erb.tt"
        elsif behavior == :invoke
          create_file "lib/templates/erb/scaffold/_form.html.erb.tt", File.read(File.join(__dir__, 'templates', 'form.tt'))
        end
      end

      def copy_files
        if behavior == :revoke
          template 'index.rb', "app/handlers/#{controller_file_name}/index_handler.rb"
          template 'create.rb', "app/handlers/#{controller_file_name}/create_handler.rb"
          template 'update.rb', "app/handlers/#{controller_file_name}/update_handler.rb"
          template 'model_form.rb', "app/handlers/#{controller_file_name}/model_form.rb"
          template 'search_form.rb', "app/handlers/#{controller_file_name}/search_form.rb"
        elsif behavior == :invoke
          empty_directory Pathname.new('app/handlers').join(controller_file_name)
          template 'index.rb', "app/handlers/#{controller_file_name}/index_handler.rb"
          template 'create.rb', "app/handlers/#{controller_file_name}/create_handler.rb"
          template 'update.rb', "app/handlers/#{controller_file_name}/update_handler.rb"
          template 'model_form.rb', "app/handlers/#{controller_file_name}/model_form.rb"
          template 'search_form.rb', "app/handlers/#{controller_file_name}/search_form.rb"
        end
      end

      hook_for :template_engine, as: :scaffold do |template_engine|
        invoke template_engine unless options.api?
      end

      hook_for :resource_route, required: true do |route|
        invoke route unless options.skip_routes?
      end

      hook_for :test_framework, as: :scaffold

      # Invoke the helper using the controller name (pluralized)
      hook_for :helper, as: :scaffold do |invoked|
        invoke invoked, [ controller_name ]
      end

      private

      def convert_to_easy_params_type(attr)
        case attr.type
        when :attachment, :attachments then ':array, of: :string'
        when :belongs_to, :references then :integer # Assuming these are foreign keys
        when :boolean then :bool
        when :date then :date
        when :datetime, :timestamp then :datetime
        when :decimal then :decimal
        when :digest then :string # Assuming this is for password digests
        when :float then :float
        when :integer then :integer
        when :rich_text then :string # Or consider a custom RichText type
        when :string, :text then :string
        when :time then :time
        when :token then :string # Or consider a custom Token type
        end
      end

      def permitted_params
          attachments, others = attributes_names.partition { |name| attachments?(name) }
          params = others.map { |name| ":#{name}" }
          params += attachments.map { |name| "#{name}: []" }
          params.join(", ")
        end

        def simple_params
          attributes.reject { |attr| attachments?(attr.name) }
        end

        def attachments?(name)
          attribute = attributes.find { |attr| attr.name == name }
          attribute&.attachments?
        end
    end
  end
