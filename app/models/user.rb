class User < ActiveRecord::Base

  after_create :set_new_stats

  # Include default devise modules. Others available are:
  # :token_authenticatable, :encryptable, :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable,
         :omniauthable, :omniauth_providers => [:google_oauth2]

  has_many :matches1, class_name: "Match", foreign_key: :player1_id
  has_many :matches2, class_name: "Match", foreign_key: :player2_id
  has_many :tournament_users



  validate :first_name,     presence: true,
                              length: { minimum: 1, maximum: 30 }

  validate :last_name,      presence: true,
                              length: { minimum: 1, maximum: 30 }

  validate :profile_name,   presence: true,
                          uniqueness: true,
                              length: { minimum: 3, maximum: 25 },
                              format: { with: /\A[a-zA-Z0-9_-]+\Z/, message: "can only contain letters, numbers, '-' or '_'"}



  def matches
    matches1 + matches2
  end

  def complete_matches
    self.matches.select { |m| m.status == 'C' }
  end

  def matches_won
    complete_matches.select { |m| m.winner == self }
  end

  def matches_lost
    complete_matches.select { |m| m.winner != self }
  end

  def record
    "#{self.wins}/#{self.losses}"
  end

  def winning_percentage
    self.total_matches_played > 0 ? self.wins.to_f / self.total_matches_played : 0
  end

  def total_matches_played
    self.wins + self.losses
  end

  def opponents
    self.matches.map(&:players).flatten.delete_if { |p| p == self }
  end

  def full_name
    "#{self.first_name} #{self.last_name}"
  end

  def to_s
    "#{self.first_name} #{self.last_name.first.upcase}."
  end

  def to_param
    self.profile_name
  end

  def update_stats
    update_wins
    update_losses
  end

  def update_wins
    old_stat = self.wins
    self.update_attribute :wins, self.matches_won.count
    logger.tagged("STATS", "WINS") { logger.info "#{self.full_name} wins updated from [#{old_stat}] to [#{self.wins}]." if old_stat != self.wins }
  end

  def update_losses
    old_stat = self.losses
    self.update_attribute :losses, self.matches_lost.count
    logger.tagged("STATS", "LOSSES") { logger.info "#{self.full_name} losses updated from [#{old_stat}] to [#{self.losses}]." if old_stat != self.losses }
  end

  def update_owp
    old_stat = self.owp
    self.update_attribute :owp, self.total_matches_played > 0 ? average_array(self.opponents.map(&:winning_percentage)) : 0
    logger.tagged("STATS", "OWP") { logger.info "#{self.full_name} owp updated from [#{old_stat}] to [#{self.owp}]." if (old_stat - self.owp) > 0.2 }
  end

  def update_oowp
    old_stat = self.oowp
    self.update_attribute :oowp, self.total_matches_played > 0 ? average_array(self.opponents.map(&:owp)) : 0
    logger.tagged("STATS", "OOWP") { logger.info "#{self.full_name} oowp updated from [#{old_stat}] to [#{self.oowp}]." if (old_stat - self.oowp) > 0.2 }
  end

  def update_rpi
    old_stat = self.rpi
    self.update_attribute :rpi, (self.winning_percentage * 0.60) + (self.owp * 0.25) + (self.oowp * 0.15)
    logger.tagged("STATS", "RPI") { logger.info "#{self.full_name} oowp updated from [#{old_stat}] to [#{self.rpi}]." if (old_stat - self.rpi) > 0.2 }
  end

  def update_rank
    old_stat = self.rank
    self.update_attribute :rank, User.where('rpi > ?', rpi).count + 1
    logger.tagged("STATS", "RANK") { logger.info "#{self.full_name} oowp updated from [#{old_stat}] to [#{self.rank}]." if old_stat != self.rank }
  end

  def self.from_omniauth(auth)
    u = where(auth.slice(:provider, :uid)).first_or_create do |user|
      user.first_name = auth.info.first_name
      user.last_name = auth.info.last_name
      user.profile_name = auth.info.name.gsub(/\s/, '').downcase
      user.email = auth.info.email
    end
    u.update_image( auth.info.image )
    u
  end

  def update_with_password(params, *options)
    if encrypted_password.blank?
      update_attributes(params, *options)
    else
      super
    end
  end

  def password_required?
    super && provider.blank?
  end

  def image
    super || 'default-avatar.png'
  end

  def update_image( image )
    update(image: image)
  end

  private

  def average_array(ary)
    ary.inject(:+).to_f / ary.size
  end

  def set_new_stats
    update_stats
    UserStatsWorker.new.perform
  end

end
