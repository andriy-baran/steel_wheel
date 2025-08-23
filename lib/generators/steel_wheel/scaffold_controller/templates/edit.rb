class <%= controller_class_name %>::EditHandler < ApplicationHandler
  params do
    integer :id, presence: true
  end

  finder :<%= singular_table_name %>, -> { <%= class_name %>.find_by(id: params.id) }, validate_existence: true
end

