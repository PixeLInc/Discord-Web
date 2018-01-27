module Discord
  class TFA
    require 'rotp'
    require 'rqrcode'

    def self.generate_secret
      ROTP::Base32.random_base32
    end

    def self.rotp(secret)
      ROTP::TOTP.new(secret, issuer: 'PixeLInc')
    end

    def self.generate_qr(secret)
      url = "otpauth://totp/PixeLInc?secret=#{secret}"

      qrgen = RQRCode::QRCode.new(url)

      qrgen.as_svg(offset: 0, color: '000', shape_rendering: 'crispEdges', module_size: 8)
    end

    def self.verify_code(rotp, code)
      # TODO: Do last_otp verification
      rotp.verify(code)
    end

    # Database STUFF
    def self.get_secret(uuid)
      data = Database.get_2fa_data(uuid)

      return nil if data.nil?

      data['secret']
    end

  end
end
