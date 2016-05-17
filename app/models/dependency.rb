class Dependency < ActiveRecord::Base

	belongs_to :obligee
	belongs_to :parent_dependency, foreign_key: 'parent_id', class_name: 'Dependency'

  has_many :admin_associations
  has_many :users, through: :admin_associations
  has_many :historic_obligees, foreign_key: 'dependency_id', class_name: 'Obligee'
  has_many :direct_sub_dependencies, foreign_key: 'parent_id', class_name: 'Dependency'
  
	validates :name, length: { minimum: 6 }

  def self.list_for_user(user)
    role = user.role
    return [] unless role == 'superadmin' or role == 'admin'
    
    if role == 'superadmin' 
      dependencies = where(active: true, parent_id: nil)
    else
      dependencies = user.dependencies
    end
    full_list = []
    tree_dependencies = []
    dependencies.each do |dependency|
      full_list.concat dependency.as_json_with_all_sub_dependencies({ top: true })
    end
    full_list
  end

  def as_json_with_all_sub_dependencies(options={})
    self_json = self.as_json
    if options[:top]
      self_json[:top] = true
    end
    dependencies = [self_json]
    self.direct_sub_dependencies.each do |sub_dependency|
      dependencies.concat sub_dependency.as_json_with_all_sub_dependencies
    end
    dependencies
  end

  def as_json(options={})
    json = super({
      only: [:id, :name, :active, :parent_id],
      include: { 
        users: { only: [:id] },
        obligee: Obligee::AS_JSON_OPTIONS,
        direct_sub_dependencies: { only: [:id] }
      }
    })
  end

  def is_sub_dependency_of(dependencies)
    is_sub_dependency = false
    dependencies.each do |dependency|
      if self.id == dependency.id or self.is_sub_dependency_of(dependency.direct_sub_dependencies)
        is_sub_dependency = true
        break
      end
    end
    is_sub_dependency
  end

  def update_minor_attributes(new_attr)
    self.name = new_attr[:name] if new_attr[:name]
  end

end
