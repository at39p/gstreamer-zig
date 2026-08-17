const DateTime = @import("DateTime.zig").DateTime;

pub const Tag = struct {
    name: [*:0]const u8,
    ValueType: type,

    // String tags
    pub const title: Tag = .{ .name = "title", .ValueType = []const u8 };
    pub const title_sortname: Tag = .{ .name = "title-sortname", .ValueType = []const u8 };
    pub const artist: Tag = .{ .name = "artist", .ValueType = []const u8 };
    pub const artist_sortname: Tag = .{ .name = "artist-sortname", .ValueType = []const u8 };
    pub const album: Tag = .{ .name = "album", .ValueType = []const u8 };
    pub const album_sortname: Tag = .{ .name = "album-sortname", .ValueType = []const u8 };
    pub const album_artist: Tag = .{ .name = "album-artist", .ValueType = []const u8 };
    pub const genre: Tag = .{ .name = "genre", .ValueType = []const u8 };
    pub const comment: Tag = .{ .name = "comment", .ValueType = []const u8 };
    pub const extended_comment: Tag = .{ .name = "extended-comment", .ValueType = []const u8 };
    pub const description: Tag = .{ .name = "description", .ValueType = []const u8 };
    pub const version: Tag = .{ .name = "version", .ValueType = []const u8 };
    pub const isrc: Tag = .{ .name = "isrc", .ValueType = []const u8 };
    pub const organization: Tag = .{ .name = "organization", .ValueType = []const u8 };
    pub const copyright: Tag = .{ .name = "copyright", .ValueType = []const u8 };
    pub const copyright_uri: Tag = .{ .name = "copyright-uri", .ValueType = []const u8 };
    pub const encoded_by: Tag = .{ .name = "encoded-by", .ValueType = []const u8 };
    pub const composer: Tag = .{ .name = "composer", .ValueType = []const u8 };
    pub const conductor: Tag = .{ .name = "conductor", .ValueType = []const u8 };
    pub const contact: Tag = .{ .name = "contact", .ValueType = []const u8 };
    pub const license: Tag = .{ .name = "license", .ValueType = []const u8 };
    pub const license_uri: Tag = .{ .name = "license-uri", .ValueType = []const u8 };
    pub const performer: Tag = .{ .name = "performer", .ValueType = []const u8 };
    pub const codec: Tag = .{ .name = "codec", .ValueType = []const u8 };
    pub const video_codec: Tag = .{ .name = "video-codec", .ValueType = []const u8 };
    pub const audio_codec: Tag = .{ .name = "audio-codec", .ValueType = []const u8 };
    pub const subtitle_codec: Tag = .{ .name = "subtitle-codec", .ValueType = []const u8 };
    pub const container_format: Tag = .{ .name = "container-format", .ValueType = []const u8 };
    pub const language_code: Tag = .{ .name = "language-code", .ValueType = []const u8 };
    pub const language_name: Tag = .{ .name = "language-name", .ValueType = []const u8 };
    pub const location: Tag = .{ .name = "location", .ValueType = []const u8 };
    pub const homepage: Tag = .{ .name = "homepage", .ValueType = []const u8 };
    pub const encoder: Tag = .{ .name = "encoder", .ValueType = []const u8 };
    pub const lyrics: Tag = .{ .name = "lyrics", .ValueType = []const u8 };
    pub const publisher: Tag = .{ .name = "publisher", .ValueType = []const u8 };
    pub const application_name: Tag = .{ .name = "application-name", .ValueType = []const u8 };

    // Uint tags
    pub const track_number: Tag = .{ .name = "track-number", .ValueType = u32 };
    pub const track_count: Tag = .{ .name = "track-count", .ValueType = u32 };
    pub const album_volume_number: Tag = .{ .name = "album-disc-number", .ValueType = u32 };
    pub const album_volume_count: Tag = .{ .name = "album-disc-count", .ValueType = u32 };
    pub const bitrate: Tag = .{ .name = "bitrate", .ValueType = u32 };
    pub const nominal_bitrate: Tag = .{ .name = "nominal-bitrate", .ValueType = u32 };
    pub const minimum_bitrate: Tag = .{ .name = "minimum-bitrate", .ValueType = u32 };
    pub const maximum_bitrate: Tag = .{ .name = "maximum-bitrate", .ValueType = u32 };
    pub const serial: Tag = .{ .name = "serial", .ValueType = u32 };
    pub const user_rating: Tag = .{ .name = "user-rating", .ValueType = u32 };
    pub const encoder_version: Tag = .{ .name = "encoder-version", .ValueType = u32 };
    pub const container_specific_track_id: Tag = .{ .name = "container-specific-track-id", .ValueType = u32 };

    // Uint64 tags
    pub const duration: Tag = .{ .name = "duration", .ValueType = u64 };

    // Double tags
    pub const geo_location_latitude: Tag = .{ .name = "geo-location-latitude", .ValueType = f64 };
    pub const geo_location_longitude: Tag = .{ .name = "geo-location-longitude", .ValueType = f64 };
    pub const geo_location_elevation: Tag = .{ .name = "geo-location-elevation", .ValueType = f64 };

    // DateTime tags
    pub const date_time: Tag = .{ .name = "datetime", .ValueType = DateTime };
};

test {
    @import("testing").refAllDeclsRecursive(@This());
}
