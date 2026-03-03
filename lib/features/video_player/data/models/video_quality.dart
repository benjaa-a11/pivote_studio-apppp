/// Calidad del video
class VideoQuality {
  final int width;
  final int height;
  final int bitrate;

  const VideoQuality({
    required this.width,
    required this.height,
    required this.bitrate,
  });

  String get resolution => '${width}x$height';
  
  String get bitrateFormatted =>
      '${(bitrate / 1000000).toStringAsFixed(1)} Mbps';

  VideoQuality copyWith({
    int? width,
    int? height,
    int? bitrate,
  }) {
    return VideoQuality(
      width: width ?? this.width,
      height: height ?? this.height,
      bitrate: bitrate ?? this.bitrate,
    );
  }
}
