class User < ActiveRecord::Base

	validates :name, presence: true
	validates :surname, presence: true
	validates :email, format: { with: GLOBALS::EMAIL_REGEX }, uniqueness: { case_sensitive: false }
	validates_inclusion_of :id_type, :in => %w(dni lc le)
	validates :person_id, presence: true, uniqueness: true
	validates_numericality_of :person_id, only_integer: true, greater_than: 0
	validates :password, length: { minimum: 6 }, allow_nil: true
	validates :auth_token, uniqueness: true

	has_secure_password
	before_create { generate_token(:auth_token) }
	before_save { self.email = email.downcase }

	has_many :admin_associations
	has_many :dependencies, through: :admin_associations
	has_many :operator_associations
	has_many :obligees, through: :operator_associations

	def generate_token(column)
		begin
			self[column] = SecureRandom.urlsafe_base64
		end while User.exists?(column => self[column])
	end

	def send_password_reset
		generate_token(:password_reset_token)
		self.password_reset_sent_at = Time.zone.now
		save!
		UserMailer.password_reset(self).deliver_now
	end

	def has_any_permit
		is_superadmin or dependencies.length > 0 or obligees.length > 0
	end

  def has_permission_for(obligee)
    if role == 'superadmin' or role == 'admin'
      true
    else
      self.obligees.include?(obligee)
    end
  end


  AS_JSON_OPTIONS = {
    only: [:person_id, :id_type, :email, :id, :name, :surname, :telephone],
    methods: [:role]
  }
	def as_json(options={})
		super(AS_JSON_OPTIONS)
	end

  def role
    if is_superadmin
      'superadmin'
    elsif dependencies.length > 0
      'admin'
    elsif obligees.length > 0
      'operator'
    else
      'user'
    end
  end

	def self.find_by_document(id_type, person_id)
		where(id_type: id_type, person_id: person_id).first
	end

	def self.find_or_initialize(params)
		user = find_by_document(params[:id_type], params[:person_id])
    
    unless user
      user = new
      user.id_type = params[:id_type]
      user.person_id = params[:person_id]
      user.name = params[:name]
      user.surname = params[:surname]
      user.email = params[:email]
      require 'securerandom'
      user.password = SecureRandom.urlsafe_base64(8)
    end

    user
	end

  def update_minor_attributes(new_attr)
    self.name = new_attr[:name] if new_attr[:name]
    self.surname = new_attr[:surname] if new_attr[:surname]
    self.email = new_attr[:email] if new_attr[:email]
  end
end
