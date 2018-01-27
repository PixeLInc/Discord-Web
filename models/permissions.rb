module Discord
  class Permissions

    PERMS = {
      :administrator => 0x00000008,
      :manage_guilds => 0x00000020
    }.freeze


    def self.has_perm(permissions, perm)
      return true if permissions & PERMS[:administrator] == PERMS[:administrator]

      permissions & perm == perm
    end


  end
end
