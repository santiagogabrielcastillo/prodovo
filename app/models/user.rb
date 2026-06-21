class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_many :quotes, dependent: :destroy

  enum :role, { general: "general", admin: "admin", stock_loader: "stock_loader" }, validate: true
end
