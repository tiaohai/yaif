class Action < ActiveRecord::Base
  validates :name, :presence => true,
                   :length => { :maximum => 200 }
  validates :http_type, :presence => true
  validates :http_method, :presence => true
  validates :target, :presence => true

  validates :service, :presence => true

  serialize_json :in_keys, :symbolize => false
  serialize_json :header, :symbolize => false

  belongs_to :service

  has_many :tasks

  def send_request(user, params)
    init_env user, params
    RequestHelper.send "#{http_type}_request".to_sym, http_method.to_sym, uri, body_, meta
  end

  private

  def init_env(user, params)
    @runtime = service.inner_runtime params || {}
    @user = user
  end

  def uri
    @runtime.eval "\"#{target}\""
  end

  def body_
    @runtime.eval body
  end

  def meta
    ret = service.meta(@user)
    raise "Need register service(#{service.name}) first" unless ret
    ret.merge! :header => header
  end
end
