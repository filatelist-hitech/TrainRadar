#!/usr/bin/env ruby
# frozen_string_literal: true

require "digest"
require "json"
require "rexml/document"
require "zlib"

module TrainRadar
  module BrandAssets
    module_function

    def load_manifest(root)
      JSON.parse(File.read(File.join(root, "assets/brand/trainradar/brand-manifest.json")))
    end
  end

  class BrandAssetsValidator
    APPROVED_MASTER_SHA256 = "74761a3e5ffc28007f29ba32c4f8c0514ef89c88d276897a61ce1de795dbab2e".freeze
    IOS_APPICON_DIR = "mobile/ios/Runner/Assets.xcassets/AppIcon.appiconset".freeze
    ANDROID_MANIFEST = "mobile/android/app/src/main/AndroidManifest.xml".freeze
    ANDROID_RES = "mobile/android/app/src/main/res".freeze
    MASTER_NAME = "trainradar-icon-master-1254.png".freeze
    ANDROID_DENSITIES = %w[mdpi hdpi xhdpi xxhdpi xxxhdpi].freeze
    IOS_APPICON_SLOTS = [
      ["iphone", "20x20", "2x", "icon-40.png"], ["iphone", "20x20", "3x", "icon-20@3x.png"],
      ["iphone", "29x29", "2x", "icon-29@2x.png"], ["iphone", "29x29", "3x", "icon-29@3x.png"],
      ["iphone", "40x40", "2x", "icon-40@2x.png"], ["iphone", "40x40", "3x", "icon-40@3x.png"],
      ["iphone", "60x60", "2x", "icon-60@2x.png"], ["iphone", "60x60", "3x", "icon-60@3x.png"],
      ["ipad", "20x20", "1x", "icon-20.png"], ["ipad", "20x20", "2x", "icon-20@2x.png"],
      ["ipad", "29x29", "1x", "icon-29.png"], ["ipad", "29x29", "2x", "icon-29@2x.png"],
      ["ipad", "40x40", "1x", "icon-40.png"], ["ipad", "40x40", "2x", "icon-40@2x.png"],
      ["ipad", "76x76", "1x", "icon-76.png"], ["ipad", "76x76", "2x", "icon-76@2x.png"],
      ["ipad", "83.5x83.5", "2x", "icon-83.5@2x.png"], ["ios-marketing", "1024x1024", "1x", "icon-1024.png"]
    ].freeze
    IOS_FILENAMES = IOS_APPICON_SLOTS.map(&:last).uniq.sort.freeze
    EXPECTED_PLATFORM_DEPLOYMENTS = (
      IOS_FILENAMES.map { |name| "#{IOS_APPICON_DIR}/#{name}" } +
      ANDROID_DENSITIES.flat_map do |density|
        [
          "#{ANDROID_RES}/mipmap-#{density}/ic_launcher.png",
          "#{ANDROID_RES}/mipmap-#{density}/ic_launcher_round.png",
          "#{ANDROID_RES}/mipmap-#{density}/ic_launcher_foreground.png",
          "#{ANDROID_RES}/drawable-#{density}/ic_stat_trainradar.png"
        ]
      end
    ).sort.freeze
    EXPECTED_CONFIGURATION_DEPLOYMENTS = [
      "#{IOS_APPICON_DIR}/Contents.json",
      "#{ANDROID_RES}/values/colors.xml",
      "#{ANDROID_RES}/mipmap-anydpi-v26/ic_launcher.xml",
      "#{ANDROID_RES}/mipmap-anydpi-v26/ic_launcher_round.xml",
      "#{ANDROID_RES}/mipmap-anydpi-v33/ic_launcher.xml",
      "#{ANDROID_RES}/mipmap-anydpi-v33/ic_launcher_round.xml"
    ].sort.freeze

    def initialize(root)
      @root = root
    end

    def validate(manifest = BrandAssets.load_manifest(@root))
      errors = []
      validate_manifest_shape(manifest, errors)
      validate_master(manifest, errors)
      validate_assets(manifest, errors)
      validate_configuration_files(manifest, errors)
      validate_ios(manifest, errors)
      validate_android(errors)
      validate_platform_scope(manifest, errors)
      errors
    end

    private

    def validate_manifest_shape(manifest, errors)
      errors << "brand manifest schema_version must be 1" unless manifest["schema_version"] == 1
      errors << "approved concept must be 05-soft-3d" unless manifest["approved_concept"] == "05-soft-3d"
      errors << "brand manifest must list iOS and Android" unless manifest["integrated_platforms"] == %w[ios android]
      errors << "brand manifest must declare every derived asset" unless manifest["assets"].is_a?(Array) && !manifest["assets"].empty?
      declared_assets = Array(manifest["assets"]).map { |asset| asset["deployment_path"] }.sort
      errors << "brand manifest must declare the fixed iOS/Android asset matrix" unless declared_assets == EXPECTED_PLATFORM_DEPLOYMENTS
      declared_configs = Array(manifest["configuration_files"]).map { |file| file["deployment_path"] }.sort
      errors << "brand manifest must declare the fixed platform configuration matrix" unless declared_configs == EXPECTED_CONFIGURATION_DEPLOYMENTS
    end

    def validate_master(manifest, errors)
      master = manifest["master"] || {}
      path = absolute_path(master["path"])
      if !File.file?(path)
        errors << "canonical master is missing: #{master["path"]}"
        return
      end

      errors << "canonical master filename must be #{MASTER_NAME}" unless File.basename(path) == MASTER_NAME
      errors << "brand manifest must record the fixed approved master checksum" unless master["sha256"] == APPROVED_MASTER_SHA256
      errors << "canonical master checksum mismatch" unless sha256(path) == APPROVED_MASTER_SHA256
      validate_png(path, master["dimensions"], master["alpha"], "canonical master", errors)

      master_dir = File.dirname(path)
      masters = Dir.children(master_dir).grep(/\.png\z/i)
      errors << "canonical master directory must contain exactly one PNG" unless masters == [MASTER_NAME]
    end

    def validate_assets(manifest, errors)
      Array(manifest["assets"]).each do |asset|
        source = absolute_path(asset["source_path"])
        deployed = absolute_path(asset["deployment_path"])
        label = "#{asset["platform"]} #{asset["purpose"]}"
        validate_png(source, asset["dimensions"], asset["alpha"], "canonical #{label}", errors)
        validate_png(deployed, asset["dimensions"], asset["alpha"], "deployed #{label}", errors)
        next unless File.file?(source) && File.file?(deployed)

        errors << "deployed asset drift: #{asset["deployment_path"]}" unless sha256(source) == sha256(deployed)
      end
    end

    def validate_configuration_files(manifest, errors)
      Array(manifest["configuration_files"]).each do |file|
        source = absolute_path(file["source_path"])
        deployed = absolute_path(file["deployment_path"])
        unless File.file?(source) && File.file?(deployed)
          errors << "configuration file missing: #{file["deployment_path"]}"
          next
        end
        errors << "configuration file drift: #{file["deployment_path"]}" unless sha256(source) == sha256(deployed)
      end
    end

    def validate_ios(manifest, errors)
      app_icon_dir = absolute_path(IOS_APPICON_DIR)
      contents_path = File.join(app_icon_dir, "Contents.json")
      return errors << "iOS AppIcon Contents.json is missing" unless File.file?(contents_path)

      contents = JSON.parse(File.read(contents_path))
      filenames = Array(contents["images"]).map { |image| image["filename"] }.compact.uniq.sort
      errors << "iOS Contents.json does not match the fixed AppIcon file set" unless filenames == IOS_FILENAMES
      slots = Array(contents["images"]).map { |image| [image["idiom"], image["size"], image["scale"], image["filename"]] }.sort
      errors << "iOS Contents.json does not match the fixed AppIcon slot matrix" unless slots == IOS_APPICON_SLOTS.sort
      errors << "iOS AppIcon contains legacy Flutter filenames" unless Dir.children(app_icon_dir).grep(/\AIcon-App-/).empty?
      filenames.each do |filename|
        errors << "iOS Contents.json references a missing file: #{filename}" unless File.file?(File.join(app_icon_dir, filename))
      end

      marketing = Array(contents["images"]).find { |image| image["idiom"] == "ios-marketing" }
      errors << "iOS marketing icon must be icon-1024.png" unless marketing&.fetch("filename", nil) == "icon-1024.png"
    rescue JSON::ParserError => error
      errors << "iOS Contents.json is invalid JSON: #{error.message}"
    end

    def validate_android(errors)
      manifest_path = absolute_path(ANDROID_MANIFEST)
      return errors << "AndroidManifest.xml is missing" unless File.file?(manifest_path)

      document = REXML::Document.new(File.read(manifest_path))
      application = document.elements["manifest/application"]
      unless application
        errors << "AndroidManifest.xml must contain application"
        return
      end
      errors << "Android application icon must be @mipmap/ic_launcher" unless application.attributes["android:icon"] == "@mipmap/ic_launcher"
      errors << "Android round icon must be @mipmap/ic_launcher_round" unless application.attributes["android:roundIcon"] == "@mipmap/ic_launcher_round"

      colors = File.join(absolute_path(ANDROID_RES), "values/colors.xml")
      errors << "Android adaptive background must be #2A1B42" unless File.file?(colors) && File.read(colors).include?("#2A1B42")
      validate_adaptive_icon("mipmap-anydpi-v26/ic_launcher.xml", false, errors)
      validate_adaptive_icon("mipmap-anydpi-v26/ic_launcher_round.xml", false, errors)
      validate_adaptive_icon("mipmap-anydpi-v33/ic_launcher.xml", true, errors)
      validate_adaptive_icon("mipmap-anydpi-v33/ic_launcher_round.xml", true, errors)
      validate_android_round_icons(errors)
      validate_notification_glyphs(errors)
    rescue REXML::ParseException => error
      errors << "AndroidManifest.xml is invalid XML: #{error.message}"
    end

    def validate_adaptive_icon(relative_path, requires_monochrome, errors)
      path = File.join(absolute_path(ANDROID_RES), relative_path)
      unless File.file?(path)
        errors << "adaptive icon missing: #{relative_path}"
        return
      end
      document = REXML::Document.new(File.read(path))
      icon = document.root
      background = icon&.elements["background"]&.attributes&.[]("android:drawable")
      foreground = icon&.elements["foreground"]&.attributes&.[]("android:drawable")
      monochrome = icon&.elements["monochrome"]&.attributes&.[]("android:drawable")
      errors << "#{relative_path} must reference the approved adaptive background" unless background == "@color/ic_launcher_background"
      errors << "#{relative_path} must reference the approved adaptive foreground" unless foreground == "@mipmap/ic_launcher_foreground"
      if requires_monochrome && monochrome != "@drawable/ic_stat_trainradar"
        errors << "#{relative_path} must use ic_stat_trainradar as Android 13 monochrome glyph"
      end
    rescue REXML::ParseException => error
      errors << "adaptive icon XML is invalid: #{relative_path}: #{error.message}"
    end

    def validate_android_round_icons(errors)
      ANDROID_DENSITIES.each do |density|
        launcher = File.join(absolute_path(ANDROID_RES), "mipmap-#{density}/ic_launcher.png")
        round = File.join(absolute_path(ANDROID_RES), "mipmap-#{density}/ic_launcher_round.png")
        next unless File.file?(launcher) && File.file?(round)

        errors << "Android round icon must preserve the approved launcher artwork: #{density}" unless sha256(launcher) == sha256(round)
      end
    end

    def validate_notification_glyphs(errors)
      ANDROID_DENSITIES.each do |density|
        path = File.join(absolute_path(ANDROID_RES), "drawable-#{density}/ic_stat_trainradar.png")
        errors << "Android notification glyph must be strict white-alpha: #{density}" unless white_alpha_png?(path)
      end
    end

    def validate_platform_scope(manifest, errors)
      web = Array(manifest["not_integrated"]).find { |entry| entry["platform"] == "web/pwa" }
      errors << "manifest must record why web/PWA is not integrated" unless web
      errors << "mobile/web exists but web/PWA is not an approved integrated platform" if Dir.exist?(absolute_path("mobile/web"))
    end

    def validate_png(path, dimensions, expected_alpha, label, errors)
      unless File.file?(path)
        errors << "#{label} is missing: #{relative_path(path)}"
        return
      end
      metadata = png_metadata(path)
      if metadata.nil?
        errors << "#{label} is not a PNG: #{relative_path(path)}"
        return
      end
      errors << "#{label} has unexpected dimensions" unless metadata[:dimensions] == dimensions
      errors << "#{label} alpha mismatch" unless metadata[:alpha] == expected_alpha
    end

    def png_metadata(path)
      bytes = File.binread(path)
      return nil unless bytes.start_with?("\x89PNG\r\n\x1A\n".b) && bytes.byteslice(12, 4) == "IHDR"

      width, height, _bit_depth, color_type, = bytes.byteslice(16, 13).unpack("NNC5")
      { dimensions: [width, height], alpha: [4, 6].include?(color_type) || bytes.include?("tRNS") }
    end

    def white_alpha_png?(path)
      return false unless File.file?(path)

      bytes = File.binread(path)
      return false unless bytes.start_with?("\x89PNG\r\n\x1A\n".b)

      index = 8
      width = height = color_type = nil
      compressed = +"".b
      while index < bytes.bytesize
        length = bytes.byteslice(index, 4).unpack1("N")
        type = bytes.byteslice(index + 4, 4)
        data = bytes.byteslice(index + 8, length)
        case type
        when "IHDR"
          width, height, bit_depth, color_type, = data.unpack("NNC5")
          return false unless bit_depth == 8 && color_type == 6
        when "IDAT"
          compressed << data
        when "IEND"
          break
        end
        index += length + 12
      end
      return false unless width && height && !compressed.empty?

      rows = Zlib::Inflate.inflate(compressed)
      stride = width * 4
      offset = 0
      previous = Array.new(stride, 0)
      height.times do
        filter = rows.getbyte(offset)
        offset += 1
        raw = rows.byteslice(offset, stride).bytes
        offset += stride
        decoded = Array.new(stride, 0)
        stride.times do |position|
          left = position >= 4 ? decoded[position - 4] : 0
          up = previous[position]
          up_left = position >= 4 ? previous[position - 4] : 0
          decoded[position] = case filter
                              when 0 then raw[position]
                              when 1 then (raw[position] + left) & 0xff
                              when 2 then (raw[position] + up) & 0xff
                              when 3 then (raw[position] + ((left + up) / 2)) & 0xff
                              when 4 then (raw[position] + paeth(left, up, up_left)) & 0xff
                              else return false
                              end
        end
        decoded.each_slice(4) do |red, green, blue, alpha|
          return false if alpha.positive? && [red, green, blue] != [255, 255, 255]
        end
        previous = decoded
      end
      true
    rescue Zlib::Error, NoMethodError
      false
    end

    def paeth(left, up, up_left)
      prediction = left + up - up_left
      left_distance = (prediction - left).abs
      up_distance = (prediction - up).abs
      up_left_distance = (prediction - up_left).abs
      return left if left_distance <= up_distance && left_distance <= up_left_distance
      return up if up_distance <= up_left_distance

      up_left
    end

    def absolute_path(relative)
      File.join(@root, relative.to_s)
    end

    def relative_path(path)
      path.delete_prefix("#{@root}/")
    end

    def sha256(path)
      Digest::SHA256.file(path).hexdigest
    end
  end
end

if $PROGRAM_NAME == __FILE__
  root = File.expand_path("..", __dir__)
  errors = TrainRadar::BrandAssetsValidator.new(root).validate
  unless errors.empty?
    warn "Brand asset validation failed:"
    errors.each { |error| warn "- #{error}" }
    exit 1
  end

  puts "PASS: canonical TrainRadar concept 05-soft-3d master and iOS/Android assets are synchronized"
end
