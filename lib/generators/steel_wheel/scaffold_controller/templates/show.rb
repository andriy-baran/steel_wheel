class <%= controller_class_name %>::ShowHandler < ApplicationHandler
  define do
    params do
      integer :id, presence: true
    end

    query do
      finder :<%= singular_table_name %>, -> { <%= class_name %>.find_by(id: id) }, existence: true
    end
  end
end
