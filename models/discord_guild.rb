module Discord
  class DiscordGuild
    attr_reader :id

    attr_reader :name

    attr_reader :icon

    attr_reader :owner_id

    attr_reader :roles

    attr_reader :emojis

    attr_reader :unavailable

    attr_reader :member_count

    attr_reader :members

    attr_reader :channels

    def initialize(id, name, icon, ownerid, roles, emoj, unav, memcount, members, channels)
      @id = id
      @name = name
      @icon = icon
      @owner_id = ownerid
      @roles = roles
      @emojis = emoj
      @unavailable = unav
      @member_count = memcount
      @members = members
      @channels = channels
    end

    def icon_url
      "https://cdn.discordapp.com/icons/#{@id}/#{@icon}.jpg"
    end
  end
end
